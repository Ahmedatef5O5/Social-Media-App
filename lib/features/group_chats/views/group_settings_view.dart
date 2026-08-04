import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/toast/app_toast.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../cubit/group_details_cubit/group_details_cubit.dart';
import '../cubit/group_list_cubit/group_list_cubit.dart';
import '../cubit/group_members_cubit/group_members_cubit.dart';
import '../helpers/group_info_action_btn_widget.dart';
import '../models/group_model.dart';
import '../services/group_chat_services.dart';

class GroupSettingsView extends StatefulWidget {
  final GroupModel group;
  final GroupMembersCubit membersCubit;
  final GroupListCubit groupListCubit;
  final GroupDetailsCubit? detailsCubit;
  final bool isAdmin;
  final String currentUserId;

  const GroupSettingsView({
    super.key,
    required this.group,
    required this.membersCubit,
    required this.groupListCubit,
    this.detailsCubit,
    required this.isAdmin,
    required this.currentUserId,
  });

  @override
  State<GroupSettingsView> createState() => _GroupSettingsViewState();
}

class _GroupSettingsViewState extends State<GroupSettingsView> {
  late final GroupChatServices _services;
  late final TextEditingController _titleController;
  bool _isSavingTitle = false;

  @override
  void initState() {
    super.initState();
    _services = context.read<GroupChatServices>();
    _titleController = TextEditingController(text: widget.group.title ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _saveTitle() async {
    final newTitle = _titleController.text.trim();
    if (newTitle == (widget.group.title ?? '')) return;
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
      if (mounted) AppToast.error('Failed to update title: $e');
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CustomLoadingIndicator()),
    );
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
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        AppToast.error('Failed to update photo: $e');
      }
    }
  }

  Future<void> _removePhoto() async {
    final confirm = await _confirm(
      context,
      title: 'Remove Group Photo',
      body: 'This will remove the current group photo for everyone.',
      confirmLabel: 'Remove',
      confirmColor: Colors.red,
    );
    if (confirm != true) return;
    try {
      await _services.removeGroupAvatar(widget.group.id);
      widget.groupListCubit.clearGroupAvatar(widget.group.id);
      if (mounted) AppToast.success('Group photo removed');
    } catch (e) {
      if (mounted) AppToast.error('Failed to remove photo: $e');
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder:
          (_) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Change Group Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _changePhoto();
                  },
                ),
                if ((widget.group.avatarUrl ?? '').isNotEmpty)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                    title: const Text(
                      'Remove Group Photo',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _removePhoto();
                    },
                  ),
              ],
            ),
          ),
    );
  }

  Future<bool?> _confirm(
    BuildContext context, {
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

  Future<void> _leaveGroup(BuildContext context, GroupModel liveGroup) async {
    final confirm = await _confirm(
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
      if (context.mounted) AppToast.error('Failed to leave group: $e');
    }
  }

  // Future<void> _deleteGroup(BuildContext context, GroupModel liveGroup) async {
  //   final confirm = await _confirm(
  //     context,
  //     title: 'Delete Group',
  //     body:
  //         liveGroup.isMember
  //             ? 'This will remove you from the group and delete the chat history on this device only. Continue?'
  //             : 'This will delete the chat history on this device only. Continue?',
  //     confirmLabel: 'Delete',
  //     confirmColor: Colors.red,
  //   );
  //   if (confirm != true) return;
  //   try {
  //     await widget.membersCubit.deleteGroup(
  //       currentUserId: widget.currentUserId,
  //       groupListCubit: widget.groupListCubit,
  //       isCurrentlyMember: liveGroup.isMember,
  //     );
  //     if (context.mounted) {
  //       Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
  //     }
  //   } catch (e) {
  //     if (context.mounted) AppToast.error('Failed to delete group: $e');
  //   }
  // }

  Future<void> _blockGroup(BuildContext context, GroupModel liveGroup) async {
    final confirm = await _confirm(
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
      if (context.mounted) AppToast.error('Failed to block group: $e');
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

        return Scaffold(
          appBar: AppBar(title: const Text('Group Settings')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (widget.isAdmin) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.image_outlined),
                  title: const Text('Group Photo'),
                  subtitle: const Text('Change or remove the group photo'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showPhotoOptions,
                ),
                const Divider(height: 24),
                const Text(
                  'Group Title',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Add a title (optional)',
                    border: const OutlineInputBorder(),
                    suffixIcon:
                        _isSavingTitle
                            ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                            : IconButton(
                              icon: const Icon(Icons.check),
                              onPressed: _saveTitle,
                            ),
                  ),
                  onSubmitted: (_) => _saveTitle(),
                ),
                const Divider(height: 32),
              ],
              if (isMember) ...[
                GroupInfoActionButton(
                  icon: Icons.exit_to_app_rounded,
                  label: 'Leave Group',
                  color: Colors.orange,
                  onTap: () => _leaveGroup(context, liveGroup),
                ),
                const SizedBox(height: 8),
              ],

              // GroupInfoActionButton(
              //   icon: Icons.delete_forever_rounded,
              //   label: 'Delete Group',
              //   color: Colors.red,
              //   onTap: () => _deleteGroup(context, liveGroup),
              // ),
              GroupInfoActionButton(
                icon: Icons.block_rounded,
                label: 'Block Group',
                color: Colors.red,
                onTap: () => _blockGroup(context, liveGroup),
              ),
            ],
          ),
        );
      },
    );
  }
}
