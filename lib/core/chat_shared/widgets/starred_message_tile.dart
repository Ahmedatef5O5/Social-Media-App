import 'package:flutter/material.dart';
import '../../helpers/formatted_date.dart';
import '../models/starred_message_entry.dart';

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

  IconData get _leadingIcon {
    switch (entry.messageType) {
      case 'image':
        return Icons.image_outlined;
      case 'video':
        return Icons.videocam_outlined;
      case 'voice':
        return Icons.mic_none_rounded;
      case 'file':
        return Icons.insert_drive_file_outlined;
      case 'call':
        return Icons.call_outlined;
      case 'gif':
        return Icons.gif_box_outlined;
      case 'sticker':
        return Icons.emoji_emotions_outlined;
      default:
        return Icons.chat_bubble_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final bubbleColor =
        entry.isMe
            ? primary
            : Theme.of(context).colorScheme.surfaceContainerHigh;
    final textColor = entry.isMe ? Colors.white : Colors.black87;

    return InkWell(
      onTap: onTap,
      onLongPress: onUnstar,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        entry.isMe ? 'You' : entry.senderName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        FormattedDate.getFormattedDate(
                          entry.createdAt.toIso8601String(),
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(14),
                        topRight: const Radius.circular(14),
                        bottomLeft: Radius.circular(entry.isMe ? 14 : 2),
                        bottomRight: Radius.circular(entry.isMe ? 2 : 14),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (entry.messageType != 'text')
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(
                              _leadingIcon,
                              size: 16,
                              color: textColor.withValues(alpha: 0.85),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            entry.previewText,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: textColor, fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: entry.isMe ? Colors.amber[200] : Colors.amber,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          FormattedDate.getMessageTime(entry.createdAt),
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.75),
                            fontSize: 10,
                          ),
                        ),
                        if (entry.isMe) ...[
                          const SizedBox(width: 2),
                          Icon(
                            entry.isRead ? Icons.done_all : Icons.done,
                            size: 13,
                            color:
                                entry.isRead
                                    ? Colors.blue[100]
                                    : Colors.white70,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
