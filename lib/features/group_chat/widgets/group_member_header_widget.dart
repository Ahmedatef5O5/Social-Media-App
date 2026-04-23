import 'package:flutter/material.dart';

class GroupMembersHeaderWidget extends StatelessWidget {
  final int count;
  final Color primary;
  final bool isAdmin;

  const GroupMembersHeaderWidget({
    super.key,
    required this.count,
    required this.primary,
    required this.isAdmin,
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
            if (isAdmin)
              TextButton.icon(
                onPressed: () {},
                icon: Icon(Icons.person_add_rounded),
                label: const Text('Add'),
              ),
          ],
        ),
      ),
    );
  }
}
