import 'package:flutter/material.dart';
import '../../../core/themes/app_colors.dart';
import '../models/groupe_message_model.dart';

class GroupReplyBubblePreview extends StatelessWidget {
  final GroupMessageModel message;
  final bool isMe;
  final String currentUserId;

  const GroupReplyBubblePreview({
    super.key,
    required this.message,
    required this.isMe,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    if (message.replyToText == null) {
      return const SizedBox.shrink();
    }

    final senderName =
        message.replyToSenderId == currentUserId
            ? 'You'
            : (message.replyToSenderName ?? 'Unknown');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      child: IntrinsicHeight(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                color: isMe ? Colors.white60 : Theme.of(context).primaryColor,
              ),

              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isMe
                            ? Colors.white.withValues(alpha: 0.2)
                            : Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.08),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        senderName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color:
                              isMe
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),

                      Text(
                        _previewText(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: isMe ? Colors.white70 : AppColors.greyColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _previewText() {
    switch (message.replyToMessageType) {
      case 'image':
        return '📷 Photo';
      case 'video':
        return '🎥 Video';
      case 'voice':
        return '🎤 Voice message';
      default:
        final t = message.replyToText ?? '';
        return t.length > 60 ? '${t.substring(0, 60)}...' : t;
    }
  }
}
