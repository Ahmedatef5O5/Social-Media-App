import 'package:flutter/material.dart';
import '../../../core/themes/app_colors.dart';
import '../models/message_model.dart';

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
