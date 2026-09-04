import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/errors/supabase_error_mapper.dart';
import '../../../core/toast/app_toast.dart';
import '../cubits/group_details_cubit/group_details_cubit.dart';
import '../cubits/group_list_cubit/group_list_cubit.dart';
import '../cubits/group_members_cubit/group_members_cubit.dart';
import '../models/group_member_model.dart';
import '../models/group_model.dart';
import '../services/group_chat_services.dart';
import '../widgets/group_avatar_editor.dart';
import '../widgets/group_confirm_dialog.dart';
import '../widgets/group_danger_zone_section.dart';
import '../widgets/group_invite_link_section.dart';
import '../widgets/group_name_title_editor.dart';
import '../widgets/group_owner_admins_section.dart';

class GroupSettingsView extends StatefulWidget {
  final GroupModel group;
  final GroupMembersCubit membersCubit;
  final GroupListCubit groupListCubit;
  final GroupDetailsCubit? detailsCubit;
  final bool isAdmin;
  final bool isOwner;
  final String currentUserId;

  const GroupSettingsView({
    super.key,
    required this.group,
    required this.membersCubit,
    required this.groupListCubit,
    this.detailsCubit,
    required this.isAdmin,
    required this.isOwner,
    required this.currentUserId,
  });

  @override
  State<GroupSettingsView> createState() => _GroupSettingsViewState();
}

class _GroupSettingsViewState extends State<GroupSettingsView> {
  late final GroupChatServices _services;

  late final TextEditingController _nameController;
  late final TextEditingController _titleController;

  bool _isSavingName = false;
  bool _isSavingTitle = false;
  String? _currentAvatarUrl;

  bool _isUploadingPhoto = false;
  bool _isRemovingPhoto = false;

  @override
  void initState() {
    super.initState();
    _services = context.read<GroupChatServices>();
    _nameController = TextEditingController(text: widget.group.name);
    _titleController = TextEditingController(text: widget.group.title ?? '');
    _currentAvatarUrl = widget.group.avatarUrl;

    if (widget.membersCubit.state is! GroupMembersLoaded) {
      widget.membersCubit.loadMembers();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _saveName(String currentName) async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty || newName == currentName) return;

    setState(() => _isSavingName = true);

    try {
      await _services.updateGroup(groupId: widget.group.id, name: newName);
      widget.groupListCubit.updateGroupName(
        groupId: widget.group.id,
        newName: newName,
      );
      if (mounted) AppToast.success('Group name updated');
    } catch (e) {
      if (mounted) AppToast.error(SupabaseErrorMapper.toUserMessage(e));
    } finally {
      if (mounted) setState(() => _isSavingName = false);
    }
  }

  Future<void> _saveTitle(String? currentTitle) async {
    final newTitle = _titleController.text.trim();
    if (newTitle == (currentTitle ?? '')) return;

    setState(() => _isSavingTitle = true);
    try {
      final value = newTitle.isEmpty ? null : newTitle;
      await _services.updateGroupTitle(widget.group.id, value);
      widget.groupListCubit.updateGroupTitle(
        groupId: widget.group.id,
        newTitle: value,
      );
      if (mounted) AppToast.success('Group title updated');
    } catch (e) {
      if (mounted) AppToast.error(SupabaseErrorMapper.toUserMessage(e));
    } finally {
      if (mounted) setState(() => _isSavingTitle = false);
    }
  }

  Future<void> _changePhoto() async {
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
      widget.groupListCubit.updateGroupAvatar(
        groupId: widget.group.id,
        newAvatarUrl: result.secureUrl,
      );
      if (mounted) {
        setState(() => _currentAvatarUrl = result.secureUrl);
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
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _removePhoto() async {
    final confirm = await GroupConfirmDialog.show(
      context,
      title: 'Remove Group Photo',
      body: 'This will remove the current group photo for everyone.',
      confirmLabel: 'Remove',
      confirmColor: Colors.red,
    );
    if (confirm != true) return;
    if (!mounted) return;

    setState(() => _isRemovingPhoto = true);

    try {
      await _services.removeGroupAvatar(widget.group.id);
      widget.groupListCubit.clearGroupAvatar(widget.group.id);
      if (mounted) {
        setState(() => _currentAvatarUrl = null);
        AppToast.success('Group photo removed');
      }
    } catch (e) {
      if (mounted) AppToast.error(SupabaseErrorMapper.toUserMessage(e));
    } finally {
      if (mounted) setState(() => _isRemovingPhoto = false);
    }
  }

  Future<void> _leaveGroup(BuildContext context, GroupModel liveGroup) async {
    final confirm = await GroupConfirmDialog.show(
      context,
      title: 'Leave Group',
      body: 'Are you sure you want to leave "${liveGroup.name}"?',
      confirmLabel: 'Leave',
      confirmColor: Colors.red,
    );
    if (confirm != true) return;
    try {
      await widget.membersCubit.leaveGroup(
        currentUserId: widget.currentUserId,
        groupListCubit: widget.groupListCubit,
      );
      if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (context.mounted) AppToast.error(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  Future<void> _blockGroup(BuildContext context, GroupModel liveGroup) async {
    final confirm = await GroupConfirmDialog.show(
      context,
      title: 'Block Group',
      body:
          liveGroup.isMember
              ? 'You will leave "${liveGroup.name}", the chat history on this device will be cleared, and you won\'t be able to be re-added to this group. Continue?'
              : 'The chat history on this device will be cleared, and you won\'t be able to be re-added to this group. Continue?',
      confirmLabel: 'Block',
      confirmColor: Colors.red,
    );
    if (confirm != true) return;
    try {
      await widget.membersCubit.blockGroup(
        currentUserId: widget.currentUserId,
        groupListCubit: widget.groupListCubit,
        isCurrentlyMember: liveGroup.isMember,
      );
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
      }
    } catch (e) {
      if (context.mounted) AppToast.error(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  Future<void> _deleteGroup(BuildContext context, GroupModel liveGroup) async {
    final confirm = await GroupConfirmDialog.show(
      context,
      title: 'Delete Group',
      body:
          'This will permanently delete "${liveGroup.name}" for you and '
          'every member — all messages, media, and members will be '
          'removed. This cannot be undone. Continue?',
      confirmLabel: 'Delete',
      confirmColor: Colors.red,
    );
    if (confirm != true) return;
    try {
      await widget.membersCubit.deleteGroup(
        currentUserId: widget.currentUserId,
        groupListCubit: widget.groupListCubit,
      );
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
      }
    } catch (e) {
      if (context.mounted) AppToast.error(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  Future<void> _handleAdminAction(
    BuildContext context,
    GroupMemberModel admin,
    String action,
  ) async {
    try {
      if (action == 'demote') {
        await widget.membersCubit.demoteAdmin(
          admin,
          currentUserId: widget.currentUserId,
        );
        if (mounted) {
          AppToast.success('${admin.userName} is no longer an admin');
        }
      } else if (action == 'remove') {
        final confirm = await GroupConfirmDialog.show(
          context,
          title: 'Remove Member',
          body: 'Remove ${admin.userName} from the group?',
          confirmLabel: 'Remove',
          confirmColor: Colors.red,
        );
        if (confirm != true) return;
        await widget.membersCubit.removeMember(
          admin,
          currentUserId: widget.currentUserId,
        );
        if (mounted) {
          AppToast.success('${admin.userName} removed from the group');
        }
      }
    } catch (e) {
      if (mounted) AppToast.error(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailsCubit = widget.detailsCubit;
    if (detailsCubit != null) {
      return BlocBuilder<GroupDetailsCubit, GroupDetailsState>(
        bloc: detailsCubit,
        builder: (context, detailsState) {
          final isMemberLive =
              detailsState is GroupDetailsLoaded
                  ? detailsState.isMember
                  : widget.group.isMember;
          return _buildBody(context, isMemberOverride: isMemberLive);
        },
      );
    }
    return _buildBody(context, isMemberOverride: null);
  }

  Widget _buildBody(BuildContext context, {required bool? isMemberOverride}) {
    return BlocBuilder<GroupListCubit, GroupListState>(
      bloc: widget.groupListCubit,
      builder: (context, listState) {
        final liveGroup =
            (listState is GroupListLoaded)
                ? listState.groups.firstWhere(
                  (g) => g.id == widget.group.id,
                  orElse: () => widget.group,
                )
                : widget.group;
        final isMember = isMemberOverride ?? liveGroup.isMember;

        return GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverAppBar(
                  title: const Text(
                    'Group Settings',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  centerTitle: true,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  pinned: false,
                  floating: true,
                  leading: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 22,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  sliver: SliverList.list(
                    children: [
                      if (widget.isAdmin) ...[
                        GroupAvatarEditor(
                          groupId: widget.group.id,
                          originalAvatarUrl: widget.group.avatarUrl,
                          currentAvatarUrl: _currentAvatarUrl,
                          liveGroupName: liveGroup.name,
                          titleController: _titleController,
                          isUploadingPhoto: _isUploadingPhoto,
                          isRemovingPhoto: _isRemovingPhoto,
                          onChangePhoto: _changePhoto,
                          onRemovePhoto: _removePhoto,
                        ),
                        const SizedBox(height: 32),

                        GroupNameTitleEditor(
                          nameController: _nameController,
                          titleController: _titleController,
                          originalName: liveGroup.name,
                          originalTitle: liveGroup.title ?? '',
                          isSavingName: _isSavingName,
                          isSavingTitle: _isSavingTitle,
                          onSaveName: () => _saveName(liveGroup.name),
                          onSaveTitle: () => _saveTitle(liveGroup.title),
                        ),
                        const SizedBox(height: 32),

                        GroupOwnerAdminsSection(
                          membersCubit: widget.membersCubit,
                          currentUserId: widget.currentUserId,
                          isOwner: widget.isOwner,
                          onAdminAction:
                              (admin, action) =>
                                  _handleAdminAction(context, admin, action),
                        ),
                        const SizedBox(height: 32),
                        const Divider(height: 1),
                        const SizedBox(height: 24),
                      ],

                      if (widget.isAdmin || widget.isOwner) ...[
                        GroupInviteLinkSection(
                          groupId: widget.group.id,
                          groupName: liveGroup.name,
                          services: _services,
                        ),
                        const SizedBox(height: 32),
                        const Divider(height: 1),
                        const SizedBox(height: 24),
                      ],

                      GroupDangerZoneSection(
                        isMember: isMember,
                        isOwner: widget.isOwner,
                        onLeave: () => _leaveGroup(context, liveGroup),
                        onBlock: () => _blockGroup(context, liveGroup),
                        onDelete: () => _deleteGroup(context, liveGroup),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
