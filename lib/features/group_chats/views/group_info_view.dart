import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../../core/cache/services/starred_message_store.dart';
import '../../../core/chat_shared/models/starred_message_entry.dart';
import '../../../core/chat_shared/views/starred_messages_view.dart';
import '../../../core/chat_shared/cubits/shared_media_cubit/shared_media_cubit.dart';
import '../../../core/chat_shared/widgets/shared_media_preview_section.dart';
import '../../../core/chat_shared/services/shared_media_data_source.dart';
import '../../../core/chat_shared/widgets/starred_messages_row.dart';
import '../../../core/errors/supabase_error_mapper.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/toast/app_toast.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../../group_calls/models/group_call_model.dart';
import '../cubits/group_details_cubit/group_details_cubit.dart';
import '../cubits/group_list_cubit/group_list_cubit.dart';
import '../cubits/group_members_cubit/group_members_cubit.dart';
import '../helpers/group_call_initiator.dart';
import '../helpers/members_list_skeleton.dart';
import '../models/group_member_model.dart';
import '../models/group_model.dart';
import '../services/group_chat_services.dart';
import '../widgets/group_info_header_widget.dart';
import '../widgets/group_info_members_list_widget.dart';
import '../widgets/group_info_quick_actions_row.dart';
import '../widgets/group_member_header_widget.dart';
import 'add_group_members_view.dart';
import 'group_settings_view.dart';

class GroupInfoView extends StatefulWidget {
  final GroupModel group;
  final GroupDetailsCubit? detailsCubit;
  final ItemScrollController? itemScrollController;

  const GroupInfoView({
    super.key,
    required this.group,
    this.detailsCubit,
    this.itemScrollController,
  });

  @override
  State<GroupInfoView> createState() => _GroupInfoViewState();
}

class _GroupInfoViewState extends State<GroupInfoView> {
  bool _isEditingName = false;
  bool _isSavingName = false;
  bool _isMuted = false;
  bool _isUploadingPhoto = false;

  final _nameController = TextEditingController();
  late final GroupChatServices _services;
  late final GroupMembersCubit _membersCubit;
  late final ScrollController _scrollController;
  late final SharedMediaCubit _mediaCubit;
  String get _currentUserId => SupabaseProvider.id;

  bool get _canShowStarredMessages => widget.detailsCubit != null;

  @override
  void initState() {
    super.initState();
    _services = context.read<GroupChatServices>();
    _membersCubit = GroupMembersCubit(_services, groupId: widget.group.id)
      ..loadMembers();
    _scrollController = ScrollController()..addListener(_onScroll);
    _nameController.text = widget.group.name;
    _mediaCubit = SharedMediaCubit(
      GroupChatMediaDataSource(services: _services, groupId: widget.group.id),
    );
    _isMuted = widget.group.isMuted;
    _loadMuteStatus();
  }

  // ── Infinite Scroll
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _membersCubit.loadMoreMembers();
    }
  }

  // Mute Status
  Future<void> _loadMuteStatus() async {
    final muted = await _services.getMyMuteStatus(widget.group.id);
    if (mounted) setState(() => _isMuted = muted);
  }

  Future<void> _toggleMute() async {
    final newValue = !_isMuted;
    setState(() => _isMuted = newValue); // optimistic
    context.read<GroupListCubit>().toggleGroupMute(widget.group.id, newValue);
    try {
      await _services.toggleMute(widget.group.id, newValue);
    } catch (e) {
      if (mounted) {
        setState(() => _isMuted = !newValue); // rollback
        context.read<GroupListCubit>().toggleGroupMute(
          widget.group.id,
          !newValue,
        );

        AppToast.error(SupabaseErrorMapper.toUserMessage(e));
      }
    }
  }

  @override
  void dispose() {
    _membersCubit.close();
    _scrollController.dispose();
    _nameController.dispose();
    _mediaCubit.close();
    super.dispose();
  }

  Future<void> _changeGroupPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (picked == null || !mounted) return;

    setState(() => _isUploadingPhoto = true);

    try {
      final result = await _services.uploadGroupAvatar(File(picked.path));
      await _services.updateGroupAvatarUrl(
        widget.group.id,
        result.secureUrl,
        result.publicId,
      );

      if (mounted) {
        context.read<GroupListCubit>().updateGroupAvatar(
          groupId: widget.group.id,
          newAvatarUrl: result.secureUrl,
        );

        if (widget.group.avatarUrl != null &&
            widget.group.avatarUrl!.isNotEmpty) {
          await CachedNetworkImage.evictFromCache(widget.group.avatarUrl!);
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(SupabaseErrorMapper.toUserMessage(e));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  Future<void> _updateGroupName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || name == widget.group.name) {
      setState(() => _isEditingName = false);
      return;
    }
    setState(() => _isSavingName = true);
    try {
      await _services.updateGroup(groupId: widget.group.id, name: name);
      if (mounted) {
        context.read<GroupListCubit>().updateGroupName(
          groupId: widget.group.id,
          newName: name,
        );
        setState(() {
          _isEditingName = false;
          _isSavingName = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSavingName = false);
        AppToast.error(SupabaseErrorMapper.toUserMessage(e));
      }
    }
  }

  Future<void> _removeMember(GroupMemberModel member) async {
    final confirm = await _showRemoveConfirmDialog(member);
    if (confirm != true) return;

    try {
      await _membersCubit.removeMember(member, currentUserId: _currentUserId);
    } catch (e) {
      if (mounted) AppToast.error(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  Future<bool?> _showRemoveConfirmDialog(GroupMemberModel member) {
    return showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Remove Member'),
            content: Text('Remove ${member.userName} from the group?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Remove',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  void _openGroupSettings(
    bool hasAdminPrivileges,
    bool isOwner,
    GroupModel liveGroup,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => GroupSettingsView(
              group: liveGroup,
              membersCubit: _membersCubit,
              groupListCubit: context.read<GroupListCubit>(),
              detailsCubit: widget.detailsCubit,
              isAdmin: hasAdminPrivileges,
              isOwner: isOwner,
              currentUserId: _currentUserId,
            ),
      ),
    );
  }

  void _openAddMembers(List<GroupMemberModel> currentMembers) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => AddGroupMembersView(
              membersCubit: _membersCubit,
              existingMemberIds: currentMembers.map((m) => m.userId).toSet(),
              currentUserId: _currentUserId,
            ),
      ),
    );
  }

  Future<void> _openStarredMessages(BuildContext context) async {
    final detailsCubit = widget.detailsCubit;
    if (detailsCubit == null) return;

    final starredIds = await StarredMessagesStore.instance.getStarredMessageIds(
      _currentUserId,
    );

    if (!context.mounted) return;

    final entries =
        detailsCubit.cachedMessages
            .where((m) => starredIds.contains(m.id))
            .map((m) => m.toStarredEntry(currentUserId: _currentUserId))
            .toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => StarredMessagesView(
              entries: entries,
              onUnstar:
                  (messageId) => StarredMessagesStore.instance.toggleStar(
                    currentUserId: _currentUserId,
                    messageId: messageId,
                  ),
              onTapEntry: (messageId) {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                final controller = widget.itemScrollController;
                if (controller != null) {
                  detailsCubit.scrollToMessage(
                    messageId: messageId,
                    itemScrollController: controller,
                  );
                }
              },
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final detailsCubit = widget.detailsCubit;
    if (detailsCubit != null) {
      return BlocBuilder<GroupDetailsCubit, GroupDetailsState>(
        bloc: detailsCubit,
        builder: (context, detailsState) {
          final isMemberLive =
              detailsState is GroupDetailsLoaded
                  ? detailsState.isMember
                  : widget.group.isMember;
          return _buildBody(context, primary, isMemberOverride: isMemberLive);
        },
      );
    }
    return _buildBody(context, primary, isMemberOverride: null);
  }

  Widget _buildBody(
    BuildContext context,
    Color primary, {
    required bool? isMemberOverride,
  }) {
    return BlocBuilder<GroupListCubit, GroupListState>(
      builder: (context, listState) {
        final liveGroup =
            (listState is GroupListLoaded)
                ? listState.groups.firstWhere(
                  (g) => g.id == widget.group.id,
                  orElse: () => widget.group,
                )
                : widget.group;

        if (!_isEditingName && _nameController.text != liveGroup.name) {
          _nameController.text = liveGroup.name;
        }

        return Scaffold(
          body: Column(
            children: [
              Expanded(
                child: BlocBuilder<GroupMembersCubit, GroupMembersState>(
                  bloc: _membersCubit,
                  builder: (context, state) {
                    final bool isLoading =
                        state is GroupMembersLoading ||
                        state is GroupMembersInitial;
                    final bool isError = state is GroupMembersError;

                    List<GroupMemberModel> membersList = [];
                    int totalCount = 0;
                    bool isLoadingMore = false;

                    if (state is GroupMembersLoaded) {
                      membersList = state.members;
                      totalCount = state.totalCount;
                      isLoadingMore = state.isLoadingMore;
                    }

                    final isOwner = _membersCubit.isCurrentUserOwner(
                      _currentUserId,
                    );

                    // Real-role admin only — used where "Owner" and "Admin"
                    // must render as visually distinct badges/menus (the
                    // members list already branches on isOwner separately).
                    final bool isAdmin = _membersCubit.isCurrentUserAdmin(
                      _currentUserId,
                    );

                    // Admin OR Owner — used for "can this person manage the
                    // group" gates (edit name/photo from the header, open
                    // the full Group Settings management UI).
                    final bool hasAdminPrivileges = _membersCubit
                        .hasAdminPrivileges(_currentUserId);

                    return CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        GroupInfoHeaderWidget(
                          group: liveGroup,

                          isAdmin: hasAdminPrivileges,
                          isEditingName: _isEditingName,
                          isSavingName: _isSavingName,
                          controller: _nameController,
                          isUploadingPhoto: _isUploadingPhoto,
                          onEditTap: () {
                            setState(() => _isEditingName = true);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _nameController.selection = TextSelection(
                                baseOffset: 0,
                                extentOffset: _nameController.text.length,
                              );
                            });
                          },
                          onSubmit: _updateGroupName,
                          onChangePhoto: _changeGroupPhoto,
                          onSettingsTap:
                              () => _openGroupSettings(
                                hasAdminPrivileges,
                                isOwner,
                                liveGroup,
                              ),
                          isMuted: _isMuted,
                        ),
                        SliverToBoxAdapter(
                          child: GroupInfoQuickActionsRow(
                            isMuted: _isMuted,
                            isMember: isMemberOverride ?? liveGroup.isMember,
                            onMessage: () => Navigator.of(context).pop(),
                            onCall:
                                () => GroupCallInitiator.initiate(
                                  context,
                                  liveGroup,
                                  GroupCallType.audio,
                                ),
                            onVideo:
                                () => GroupCallInitiator.initiate(
                                  context,
                                  liveGroup,
                                  GroupCallType.video,
                                ),
                            onToggleMute: _toggleMute,
                          ),
                        ),
                        if (_canShowStarredMessages)
                          SliverToBoxAdapter(
                            child: StarredMessagesRow(
                              primary: primary,
                              onTap: () => _openStarredMessages(context),
                            ),
                          ),

                        if (isLoading)
                          const SliverToBoxAdapter(child: MembersListSkeleton())
                        else ...[
                          GroupMembersHeaderWidget(
                            count: totalCount,
                            primary: primary,
                            isOwner: isOwner,
                            isAdmin: isAdmin,
                            onAddTap: () => _openAddMembers(membersList),
                          ),
                          if (isError)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.all(40),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Failed to load members'),
                                      TextButton(
                                        onPressed:
                                            () => _membersCubit.loadMembers(),
                                        child: const Text('Retry'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          else ...[
                            GroupInfoMembersList(
                              members: membersList,
                              currentUserId: _currentUserId,
                              isOwner: isOwner,
                              isAdmin: isAdmin,

                              primary: primary,
                              onPromote: (member) async {
                                try {
                                  await _membersCubit.promoteToAdmin(
                                    member,
                                    currentUserId: _currentUserId,
                                  );
                                  AppToast.success(
                                    '${member.userName} is now an admin',
                                  );
                                } catch (e) {
                                  AppToast.error(
                                    SupabaseErrorMapper.toUserMessage(e),
                                  );
                                }
                              },
                              onDemote: (member) async {
                                try {
                                  await _membersCubit.demoteAdmin(
                                    member,
                                    currentUserId: _currentUserId,
                                  );
                                  AppToast.success(
                                    '${member.userName} is no longer an admin',
                                  );
                                } catch (e) {
                                  AppToast.error(
                                    SupabaseErrorMapper.toUserMessage(e),
                                  );
                                }
                              },
                              onRemove: _removeMember,
                            ),

                            if (isLoadingMore)
                              const SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: CustomLoadingIndicator(),
                                  ),
                                ),
                              ),

                            SliverToBoxAdapter(
                              child: SharedMediaPreviewSection(
                                mediaCubit: _mediaCubit,
                                onShowInChat: (sheetContext, messageId) {
                                  Navigator.of(sheetContext).pop();
                                  Navigator.of(sheetContext).pop();
                                  final controller =
                                      widget.itemScrollController;
                                  if (controller != null) {
                                    widget.detailsCubit?.scrollToMessage(
                                      messageId: messageId,
                                      itemScrollController: controller,
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
