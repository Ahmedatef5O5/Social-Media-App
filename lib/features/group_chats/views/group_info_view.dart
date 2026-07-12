import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/toast/app_toast.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../cubit/group_list_cubit/group_list_cubit.dart';
import '../cubit/group_members_cubit/group_members_cubit.dart';
import '../models/group_member_model.dart';
import '../models/group_model.dart';
import '../services/group_chat_services.dart';
import '../widgets/group_info_actions_section_widget.dart';
import '../widgets/group_info_header_widget.dart';
import '../widgets/group_info_members_list_widget.dart';
import '../widgets/group_member_header_widget.dart';

class GroupInfoView extends StatefulWidget {
  final GroupModel group;
  const GroupInfoView({super.key, required this.group});

  @override
  State<GroupInfoView> createState() => _GroupInfoViewState();
}

class _GroupInfoViewState extends State<GroupInfoView> {
  bool _isEditingName = false;
  String? _currentAvatarUrl;

  final _nameController = TextEditingController();
  late final GroupChatServices _services;
  late final GroupMembersCubit _membersCubit;
  late final ScrollController _scrollController;

  String get _currentUserId => SupabaseProvider.id;

  @override
  void initState() {
    super.initState();
    _services = context.read<GroupChatServices>();

    _membersCubit = GroupMembersCubit(_services, groupId: widget.group.id)
      ..loadMembers();

    _scrollController = ScrollController()..addListener(_onScroll);

    _nameController.text = widget.group.name;
    _currentAvatarUrl = widget.group.avatarUrl;
  }

  // ── Infinite Scroll
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _membersCubit.loadMoreMembers();
    }
  }

  @override
  void dispose() {
    _membersCubit.close();
    _scrollController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _changeGroupPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (picked == null || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await _services.uploadGroupAvatar(File(picked.path));
      await _services.updateGroupAvatarUrl(
        widget.group.id,
        result.secureUrl,
        result.publicId,
      );

      if (mounted) {
        Navigator.pop(context);

        setState(() => _currentAvatarUrl = result.secureUrl);

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
        Navigator.pop(context);

        AppToast.error('Failed to update photo: $e');
      }
    }
  }

  Future<void> _updateGroupName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || name == widget.group.name) {
      setState(() => _isEditingName = false);
      return;
    }
    await _services.updateGroup(groupId: widget.group.id, name: name);
    if (mounted) setState(() => _isEditingName = false);
  }

  Future<void> _removeMember(GroupMemberModel member) async {
    final confirm = await _showConfirmDialog(
      title: 'Remove Member',
      body: 'Remove ${member.userName} from the group?',
      confirmLabel: 'Remove',
      confirmColor: Colors.red,
    );

    if (confirm == true) {
      await _services.removeMember(widget.group.id, member.userId);
      await _membersCubit.refresh();
    }
  }

  Future<void> _leaveGroup() async {
    final confirm = await _showConfirmDialog(
      title: 'Leave Group',
      body: 'Are you sure you want to leave "${widget.group.name}"?',
      confirmLabel: 'Leave',
      confirmColor: Colors.red,
    );

    if (confirm == true && mounted) {
      await _services.leaveGroup(widget.group.id);
      if (mounted) {
        Navigator.popUntil(context, (r) => r.isFirst);
      }
    }
  }

  Future<void> _deleteGroup() async {
    final confirm = await _showConfirmDialog(
      title: 'Delete Group',
      body:
          'This will permanently delete the group and all messages. Continue?',
      confirmLabel: 'Delete',
      confirmColor: Colors.red,
    );

    if (confirm == true && mounted) {
      await _services.deleteGroup(widget.group.id);
      if (mounted) {
        Navigator.popUntil(context, (r) => r.isFirst);
      }
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String body,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  confirmLabel,
                  style: TextStyle(color: confirmColor),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      body: BlocBuilder<GroupMembersCubit, GroupMembersState>(
        bloc: _membersCubit,
        builder: (context, state) {
          final bool isLoading =
              state is GroupMembersLoading || state is GroupMembersInitial;
          final bool isError = state is GroupMembersError;

          List<GroupMemberModel> membersList = [];
          int totalCount = 0;
          bool isLoadingMore = false;

          if (state is GroupMembersLoaded) {
            membersList = state.members;
            totalCount = state.totalCount;
            isLoadingMore = state.isLoadingMore;
          }

          final bool isAdmin = _membersCubit.isCurrentUserAdmin(_currentUserId);

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              GroupInfoHeader(
                group: widget.group.copyWith(avatarUrl: _currentAvatarUrl),
                isAdmin: isAdmin,
                isEditingName: _isEditingName,
                controller: _nameController,
                onEditTap: () => setState(() => _isEditingName = true),
                onSubmit: _updateGroupName,
                onChangePhoto: _changeGroupPhoto,
              ),

              GroupMembersHeaderWidget(
                count: totalCount,
                primary: primary,
                isAdmin: isAdmin,
              ),

              if (isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CustomLoadingIndicator()),
                  ),
                )
              else if (isError)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Failed to load members'),
                          TextButton(
                            onPressed: () => _membersCubit.loadMembers(),
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
                  isAdmin: isAdmin,
                  primary: primary,
                  onRemove: _removeMember,
                ),

                if (isLoadingMore)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CustomLoadingIndicator()),
                    ),
                  ),
              ],

              GroupInfoActionsSection(
                isAdmin: isAdmin,
                onLeave: _leaveGroup,
                onDelete: _deleteGroup,
              ),
            ],
          );
        },
      ),
    );
  }
}
