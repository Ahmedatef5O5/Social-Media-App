import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/features/group_chat/widgets/group_info_action_btn_widget.dart';

class GroupInfoActionsSection extends StatelessWidget {
  final bool isAdmin;
  final VoidCallback onLeave;
  final VoidCallback onDelete;

  const GroupInfoActionsSection({
    super.key,
    required this.isAdmin,
    required this.onLeave,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          children: [
            const Divider(),
            const Gap(8),
            GroupInfoActionButton(
              icon: Icons.exit_to_app_rounded,
              label: 'Leave Group',
              color: Colors.orange,
              onTap: onLeave,
            ),
            if (isAdmin) ...[
              const Gap(8),
              GroupInfoActionButton(
                icon: Icons.delete_forever_rounded,
                label: 'Delete Group',
                color: Colors.red,
                onTap: onDelete,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
