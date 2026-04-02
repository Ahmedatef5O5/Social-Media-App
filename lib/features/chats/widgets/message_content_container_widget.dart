import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/features/chats/widgets/image_message_widget.dart';
import 'package:social_media_app/features/chats/widgets/video_message_widget.dart';
import 'package:social_media_app/features/chats/widgets/voice_message_bubble_widget.dart';
import '../../../core/helpers/formatted_date.dart';
import '../../../core/themes/app_colors.dart';
import '../models/message_model.dart';

class MessageContentContainer extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  const MessageContentContainer({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color:
                isMe
                    ? AppColors.primaryColor
                    : AppColors.grey3.withValues(alpha: 0.3),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(isMe ? 20 : 0),
              bottomRight: Radius.circular(isMe ? 0 : 20),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.grey.withValues(alpha: 0.18),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.messageType == 'image' && message.imageUrl != null)
                ImageMessageWidget(
                  imageUrl: message.imageUrl!,
                  caption: message.caption,
                ),
              if (message.messageType == 'video' && message.videoUrl != null)
                VideoMessageWidget(
                  videoUrl: message.videoUrl!,
                  caption: message.caption,
                ),

              if (message.messageType == 'voice' && message.voiceUrl != null)
                VoiceMessageBubbleWidget(
                  voiceUrl: message.voiceUrl!,
                  isMe: isMe,
                ),

              if (message.text.isNotEmpty || message.caption != null)
                Text(
                  message.caption ?? message.text,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: isMe ? AppColors.white : AppColors.black87,
                    fontSize: 15,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    FormattedDate.getMessageTime(message.createdAt),
                    style: TextStyle(
                      color: isMe ? AppColors.white70 : AppColors.black54,
                      fontSize: 10,
                    ),
                  ),
                  if (isMe) ...[
                    const Gap(2),
                    Icon(
                      message.isRead ? Icons.done_all : Icons.done,
                      size: 14,
                      color:
                          message.isRead ? Colors.blue[200] : AppColors.white70,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        if (message.reaction != null && message.reaction!.isNotEmpty)
          Positioned(
            bottom: -36,
            right: isMe ? 8 : null,
            left: isMe ? null : 8,
            child: Container(
              margin: EdgeInsets.only(
                top: 2,
                bottom:
                    message.reaction != null && message.reaction!.isNotEmpty
                        ? 18
                        : 2,
              ),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                  ),
                ],
              ),

              child: Text(
                message.reaction!,
                style: const TextStyle(
                  fontSize: 14,
                  // fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
