import 'package:flutter/material.dart';
import '../../helpers/formatted_date.dart';
import '../../widgets/app_avatar.dart';
import '../models/starred_message_entry.dart';
import 'starred_message_content.dart';

class StarredMessageTile extends StatelessWidget {
  final StarredMessageEntry entry;
  final VoidCallback onTap;
  final VoidCallback onUnstar;

  const StarredMessageTile({
    super.key,
    required this.entry,
    required this.onTap,
    required this.onUnstar,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onUnstar,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppAvatar(imageUrl: entry.senderAvatar, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        entry.isMe ? 'You' : entry.senderName,
                        maxLines: 1,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  FormattedDate.getFormattedDate(
                    entry.createdAt.toIso8601String(),
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  StarredMessageContent(entry: entry),
                  const SizedBox(height: 4),
                  _StarredFooter(entry: entry),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarredFooter extends StatelessWidget {
  final StarredMessageEntry entry;
  const _StarredFooter({required this.entry});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, size: 13, color: Colors.amber),
        const SizedBox(width: 3),
        Text(
          FormattedDate.getMessageTime(entry.createdAt),
          style: TextStyle(color: color, fontSize: 10.5),
        ),
        if (entry.isMe) ...[
          const SizedBox(width: 3),
          Icon(
            entry.isRead ? Icons.done_all : Icons.done,
            size: 13,
            color: entry.isRead ? Colors.blue : color,
          ),
        ],
      ],
    );
  }
}
