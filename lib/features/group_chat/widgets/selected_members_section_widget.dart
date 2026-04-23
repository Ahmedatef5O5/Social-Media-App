import 'package:flutter/material.dart';

class SelectedMembersSection extends StatelessWidget {
  final Set<String> selectedUserIds;
  final List<Map<String, dynamic>> allUsers;
  final Color primary;
  final Function(String) onRemove;

  const SelectedMembersSection({
    super.key,
    required this.selectedUserIds,
    required this.allUsers,
    required this.primary,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedUserIds.isEmpty) return const SizedBox();

    return SizedBox(
      height: 70,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children:
            selectedUserIds.map((uid) {
              final user = allUsers.firstWhere((u) => u['id'] == uid);

              return GestureDetector(
                onTap: () => onRemove(uid),
                child: CircleAvatar(child: Text(user['name'][0])),
              );
            }).toList(),
      ),
    );
  }
}
