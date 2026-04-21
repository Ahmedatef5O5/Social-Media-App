import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/group_member_model.dart';
import '../models/group_model.dart';
import '../services/group_chat_services.dart';

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
    _loadMembers();
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
    } catch (e) {
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

  Future<void> _changeGroupPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;
    final url = await _services.uploadGroupFile(File(picked.path), 'image');
    await _services.updateGroup(groupId: widget.group.id, avatarUrl: url);
    if (mounted) setState(() {});
  }

  Future<void> _removeMember(GroupMemberModel member) async {
    final confirm = await _showConfirmDialog(
      context,
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
      context,
      title: 'Leave Group',
      body: 'Are you sure you want to leave "${widget.group.name}"?',
      confirmLabel: 'Leave',
      confirmColor: Colors.red,
    );
    if (confirm == true && mounted) {
      await _services.leaveGroup(widget.group.id);
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  Future<void> _deleteGroup() async {
    final confirm = await _showConfirmDialog(
      context,
      title: 'Delete Group',
      body:
          'This will permanently delete the group and all messages. Continue?',
      confirmLabel: 'Delete',
      confirmColor: Colors.red,
    );
    if (confirm == true && mounted) {
      await _services.deleteGroup(widget.group.id);
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  Future<bool?> _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
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
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasAvatar = widget.group.avatarUrl?.isNotEmpty == true;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── Collapsible Header ──
          SliverAppBar(
            automaticallyImplyLeading: false,
            expandedHeight: 240,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [primary, primary.withValues(alpha: 0.7)],
                      ),
                    ),
                  ),
                  // Group avatar
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Gap(30),
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 52,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.25,
                              ),
                              backgroundImage:
                                  hasAvatar
                                      ? CachedNetworkImageProvider(
                                        widget.group.avatarUrl!,
                                      )
                                      : null,
                              child:
                                  !hasAvatar
                                      ? Text(
                                        widget.group.name.isNotEmpty
                                            ? widget.group.name[0].toUpperCase()
                                            : 'G',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                      : null,
                            ),
                            if (_isAdmin)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _changeGroupPhoto,
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: primary,
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.camera_alt_rounded,
                                      size: 16,
                                      color: primary,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const Gap(12),
                        // Group name (editable for admin)
                        GestureDetector(
                          onTap:
                              _isAdmin
                                  ? () => setState(() => _isEditingName = true)
                                  : null,
                          child:
                              _isEditingName
                                  ? SizedBox(
                                    width: 200,
                                    child: TextField(
                                      controller: _nameController,
                                      autofocus: true,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      decoration: const InputDecoration(
                                        border: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.white60,
                                          ),
                                        ),
                                      ),
                                      onSubmitted: (_) => _updateGroupName(),
                                    ),
                                  )
                                  : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        widget.group.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (_isAdmin) ...[
                                        const Gap(6),
                                        const Icon(
                                          Icons.edit_rounded,
                                          color: Colors.white60,
                                          size: 16,
                                        ),
                                      ],
                                    ],
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Navigator.of(context).pop(),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Members section ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Row(
                children: [
                  Text(
                    '${_members.length} Members',
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  if (_isAdmin)
                    TextButton.icon(
                      onPressed: () {
                        // TODO: navigate to add members screen
                        // Uses existing CreateGroupView logic
                      },
                      icon: Icon(
                        Icons.person_add_rounded,
                        size: 16,
                        color: primary,
                      ),
                      label: Text(
                        'Add',
                        style: TextStyle(color: primary, fontSize: 13),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Members list ──
          _isLoading
              ? const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
              : SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final member = _members[index];
                  final isCurrentUser = member.userId == _currentUserId;
                  final isMemberAdmin = member.role == GroupMemberRole.admin;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: primary.withValues(alpha: 0.12),
                      backgroundImage:
                          member.userAvatar?.isNotEmpty == true
                              ? CachedNetworkImageProvider(member.userAvatar!)
                              : null,
                      child:
                          member.userAvatar?.isEmpty != false
                              ? Text(
                                member.userName.isNotEmpty
                                    ? member.userName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                              : null,
                    ),
                    title: Row(
                      children: [
                        Text(
                          isCurrentUser ? 'You' : member.userName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (isMemberAdmin) ...[
                          const Gap(6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Admin',
                              style: TextStyle(
                                color: primary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing:
                        _isAdmin && !isCurrentUser
                            ? IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline_rounded,
                                color: Colors.redAccent,
                                size: 22,
                              ),
                              onPressed: () => _removeMember(member),
                            )
                            : null,
                  );
                }, childCount: _members.length),
              ),

          // ── Action buttons ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                children: [
                  const Divider(),
                  const Gap(8),
                  // Leave group
                  _ActionButton(
                    icon: Icons.exit_to_app_rounded,
                    label: 'Leave Group',
                    color: Colors.orange,
                    onTap: _leaveGroup,
                  ),
                  if (_isAdmin) ...[
                    const Gap(8),
                    _ActionButton(
                      icon: Icons.delete_forever_rounded,
                      label: 'Delete Group',
                      color: Colors.red,
                      onTap: _deleteGroup,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const Gap(12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
