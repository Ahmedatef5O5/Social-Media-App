import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../cubit/group_list_cubit/group_list_cubit.dart';
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
  List<GroupMemberModel> _members = [];
  bool _isLoading = true;
  bool _isEditingName = false;
  String? _currentAvatarUrl;

  final _nameController = TextEditingController();
  final _services = GroupChatServices();

  String get _currentUserId => Supabase.instance.client.auth.currentUser!.id;

  bool get _isAdmin => _members.any(
    (m) => m.userId == _currentUserId && m.role == GroupMemberRole.admin,
  );

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.group.name;
    _currentAvatarUrl = widget.group.avatarUrl;
    _loadMembers();
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
      final url = await _services.uploadGroupAvatar(File(picked.path));
      await _services.updateGroup(groupId: widget.group.id, avatarUrl: url);

      if (mounted) {
        Navigator.pop(context);

        setState(() => _currentAvatarUrl = url);

        context.read<GroupListCubit>().updateGroupAvatar(
          groupId: widget.group.id,
          newAvatarUrl: url,
        );

        if (widget.group.avatarUrl != null &&
            widget.group.avatarUrl!.isNotEmpty) {
          await CachedNetworkImage.evictFromCache(widget.group.avatarUrl!);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);
    try {
      final members = await _services.getGroupMembers(widget.group.id);
      if (mounted) {
        setState(() {
          _members = members;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
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
      await _loadMembers();
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
      body: CustomScrollView(
        slivers: [
          GroupInfoHeader(
            group: widget.group.copyWith(avatarUrl: _currentAvatarUrl),
            isAdmin: _isAdmin,
            isEditingName: _isEditingName,
            controller: _nameController,
            onEditTap: () => setState(() => _isEditingName = true),
            onSubmit: _updateGroupName,
            onChangePhoto: _changeGroupPhoto,
          ),

          GroupMembersHeaderWidget(
            count: _members.length,
            primary: primary,
            isAdmin: _isAdmin,
          ),

          _isLoading
              ? const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CustomLoadingIndicator()),
                ),
              )
              : GroupInfoMembersList(
                members: _members,
                currentUserId: _currentUserId,
                isAdmin: _isAdmin,
                primary: primary,
                onRemove: _removeMember,
              ),

          GroupInfoActionsSection(
            isAdmin: _isAdmin,
            onLeave: _leaveGroup,
            onDelete: _deleteGroup,
          ),
        ],
      ),
    );
  }
}
