import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../models/groupe_message_model.dart';

class GroupReplyPreviewBar extends StatelessWidget {
  final GroupMessageModel reply;
  final VoidCallback onDismiss;
  const GroupReplyPreviewBar({
    super.key,
    required this.reply,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color:
          isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100,
      child: Row(
        children: [
          Container(width: 3, height: 36, color: primary),
          const Gap(8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  reply.senderName,
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  reply.text.isNotEmpty
                      ? reply.text
                      : (reply.caption ?? '📎 Media'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}
