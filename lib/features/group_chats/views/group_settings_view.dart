import 'package:flutter/material.dart';
import '../../../core/toast/app_toast.dart';
import '../cubit/group_members_cubit/group_members_cubit.dart';
import '../helpers/group_info_action_btn_widget.dart';
import '../models/group_model.dart';

class GroupSettingsView extends StatelessWidget {
  final GroupModel group;
  final GroupMembersCubit membersCubit;
  final bool isAdmin;
  final String currentUserId;

  const GroupSettingsView({
    super.key,
    required this.group,
    required this.membersCubit,
    required this.isAdmin,
    required this.currentUserId,
  });

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

  Future<void> _leaveGroup(BuildContext context) async {
    final confirm = await _confirm(
      context,
      title: 'Leave Group',
      body: 'Are you sure you want to leave "${group.name}"?',
      confirmLabel: 'Leave',
      confirmColor: Colors.red,
    );
    if (confirm != true) return;

    try {
      await membersCubit.leaveGroup(currentUserId);
      if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (context.mounted) AppToast.error('Failed to leave group: $e');
    }
  }

  Future<void> _deleteGroup(BuildContext context) async {
    final confirm = await _confirm(
      context,
      title: 'Delete Group',
      body:
          'This will permanently delete the group and all messages. Continue?',
      confirmLabel: 'Delete',
      confirmColor: Colors.red,
    );
    if (confirm != true) return;

    try {
      await membersCubit.deleteGroup(currentUserId);
      if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (context.mounted) AppToast.error('Failed to delete group: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Group Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GroupInfoActionButton(
            icon: Icons.exit_to_app_rounded,
            label: 'Leave Group',
            color: Colors.orange,
            onTap: () => _leaveGroup(context),
          ),
          if (isAdmin) ...[
            const SizedBox(height: 8),
            GroupInfoActionButton(
              icon: Icons.delete_forever_rounded,
              label: 'Delete Group',
              color: Colors.red,
              onTap: () => _deleteGroup(context),
            ),
          ],
        ],
      ),
    );
  }
}
