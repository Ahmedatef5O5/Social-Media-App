import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class ChatSelectionAppBar extends StatelessWidget {
  final int selectedCount;
  final bool canDeleteForEveryone;
  final VoidCallback onCancel;
  final VoidCallback onDelete;
  final VoidCallback onForward;
  final VoidCallback onInfo;

  const ChatSelectionAppBar({
    super.key,
    required this.selectedCount,
    required this.canDeleteForEveryone,
    required this.onCancel,
    required this.onDelete,
    required this.onForward,
    required this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.close, color: primary),
            onPressed: onCancel,
            tooltip: 'Cancel selection',
          ),
          const Gap(4),
          Text(
            '$selectedCount',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.info_outline, color: primary),
            onPressed: onInfo,
            tooltip: 'Info',
          ),
          IconButton(
            icon: Icon(Icons.forward_rounded, color: primary),
            onPressed: onForward,
            tooltip: 'Forward',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: onDelete,
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }
}
