import 'package:flutter/material.dart';

class GroupMembersHeaderWidget extends StatelessWidget {
  final int count;
  final Color primary;
  final bool isOwner;
  final bool isAdmin;
  final VoidCallback onAddTap;

  const GroupMembersHeaderWidget({
    super.key,
    required this.count,
    required this.primary,
    required this.isOwner,
    required this.isAdmin,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        child: Row(
          children: [
            Text('$count Members'),
            const Spacer(),
            if (isAdmin || isOwner)
              TextButton.icon(
                onPressed: onAddTap,
                icon: Icon(
                  Icons.person_add_rounded,
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.85),
                ),
                label: Text(
                  'Add',

                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.85),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
