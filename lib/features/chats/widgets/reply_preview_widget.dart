import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/themes/app_colors.dart';
import '../models/message_model.dart';

class ReplyPreviewBar extends StatelessWidget {
  final MessageModel replyTo;
  final bool isMe;
  final String senderName;
  final VoidCallback onCancel;
  const ReplyPreviewBar({
    super.key,
    required this.replyTo,
    required this.isMe,
    required this.onCancel,
    required this.senderName,
  });

  @override
  Widget build(BuildContext context) {
    final preview = _previewText();
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isMe ? 'You' : senderName,
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const Gap(2),
                Text(
                  preview,
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

  String _previewText() {
    switch (replyTo.messageType) {
      case 'image':
        return '📷 Photo';
      case 'video':
        return '🎥 Video';
      case 'voice':
        return '🎤 Voice message';
      default:
        final t = replyTo.caption ?? replyTo.text;
        return t.length > 60 ? '${t.substring(0, 60)}...' : t;
    }
  }
}

class ReplyBubblePreview extends StatelessWidget {
  final MessageModel message;
  final String? replyText;
  final String? replyType;
  final bool isMe;
  final String currentUserId;
  final String receiverName;

  const ReplyBubblePreview({
    super.key,
    required this.replyText,
    required this.replyType,
    required this.isMe,
    required this.message,
    required this.currentUserId,
    required this.receiverName,
  });

  @override
  Widget build(BuildContext context) {
    final String senderName =
        message.replyToSenderId == currentUserId ? 'You' : receiverName;

    if (replyText == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      child: IntrinsicHeight(
        child: ClipRRect(
          borderRadius: BorderRadiusDirectional.all(Radius.circular(8)),
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
                        replyText!,
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
}
