import 'package:flutter/material.dart';

class UsersList extends StatelessWidget {
  final List<Map<String, dynamic>> users;
  final Set<String> selectedIds;
  final Color primary;
  final bool isDark;
  final Function(String) onToggle;

  const UsersList({
    super.key,
    required this.users,
    required this.selectedIds,
    required this.primary,
    required this.isDark,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (_, i) {
        final user = users[i];
        final uid = user['id'];
        final selected = selectedIds.contains(uid);

        return ListTile(title: Text(user['name']), onTap: () => onToggle(uid));
      },
    );
  }
}
