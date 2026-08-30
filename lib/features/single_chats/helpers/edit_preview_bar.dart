import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/themes/app_colors.dart';
import '../models/message_model.dart';

class EditPreviewBar extends StatelessWidget {
  final MessageModel editingMessage;
  final VoidCallback onCancel;

  const EditPreviewBar({
    super.key,
    required this.editingMessage,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final preview = editingMessage.caption ?? editingMessage.text;
    final trimmed =
        preview.length > 60 ? '${preview.substring(0, 60)}...' : preview;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: Theme.of(context).primaryColor, width: 3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.edit_outlined,
            size: 16,
            color: Theme.of(context).primaryColor,
          ),
          const Gap(8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Editing message',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const Gap(2),
                Text(
                  trimmed,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.greyColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.close, size: 18),
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}
