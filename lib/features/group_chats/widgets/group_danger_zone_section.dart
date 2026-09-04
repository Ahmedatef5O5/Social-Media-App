import 'package:flutter/material.dart';
import '../helpers/group_info_action_btn_widget.dart';

class GroupDangerZoneSection extends StatelessWidget {
  final bool isMember;
  final bool isOwner;
  final VoidCallback onLeave;
  final VoidCallback onBlock;
  final VoidCallback onDelete;

  const GroupDangerZoneSection({
    super.key,
    required this.isMember,
    required this.isOwner,
    required this.onLeave,
    required this.onBlock,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isMember) ...[
          GroupInfoActionButton(
            icon: Icons.exit_to_app_rounded,
            label: 'Leave Group',
            color: Colors.orange,
            onTap: onLeave,
          ),
          const SizedBox(height: 12),
        ],
        GroupInfoActionButton(
          icon: Icons.block_rounded,
          label: 'Block Group',
          color: Colors.red,
          onTap: onBlock,
        ),
        if (isOwner) ...[
          const SizedBox(height: 12),
          GroupInfoActionButton(
            icon: Icons.delete_forever_rounded,
            label: 'Delete Group',
            color: Colors.red.shade900,
            onTap: onDelete,
          ),
        ],
      ],
    );
  }
}
