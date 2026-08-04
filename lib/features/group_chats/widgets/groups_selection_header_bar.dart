import 'package:flutter/material.dart';

class GroupsSelectionHeaderBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  const GroupsSelectionHeaderBar({
    super.key,
    required this.selectedCount,
    required this.onCancel,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: onCancel,
          ),
          Expanded(
            child: Text(
              '$selectedCount selected',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
