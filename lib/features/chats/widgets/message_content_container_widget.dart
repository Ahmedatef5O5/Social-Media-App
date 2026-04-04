import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/helpers/chat_helper.dart';
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
    final bool isImage = message.messageType == 'image';
    final bool isVideo = message.messageType == 'video';
    final bool hasReaction =
        message.reaction != null && message.reaction!.isNotEmpty;
    final String displayDraft = message.caption ?? message.text;
    Widget timeAndStatus(Color textColor, Color? iconColor) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.ltr,
        children: [
          Text(
            FormattedDate.getMessageTime(message.createdAt),
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              color: isMe ? AppColors.white70 : AppColors.black54,
              fontSize: 9,
            ),
          ),
          if (isMe) ...[
            const Gap(2),
            Icon(
              message.isRead ? Icons.done_all : Icons.done,
              size: 12,
              color: message.isRead ? Colors.blue[200] : iconColor,
            ),
          ],
        ],
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: EdgeInsets.only(
            top: 2,
            left: 0,
            right: 0,
            bottom: hasReaction ? 28 : 2,
          ),
          padding:
              isImage
                  ? EdgeInsets.symmetric(horizontal: 2, vertical: 2)
                  : EdgeInsets.only(
                    left: isVideo ? 4 : 8,
                    right: isVideo ? 4 : 12,
                    bottom: isVideo ? 4 : 8,
                    top: isVideo ? 4 : 2,
                  ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color:
                isMe
                    ? Theme.of(context).primaryColor
                    : AppColors.grey3.withValues(alpha: 0.3),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(isMe ? 20 : 0),
              bottomRight: Radius.circular(isMe ? 0 : 20),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.grey1.withValues(alpha: 0.8),
                // spreadRadius: 1,
                // blurRadius: 5,
                // offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isImage && message.imageUrl != null)
                ImageMessageWidget(
                  imageUrl: message.imageUrl!,
                  caption: message.caption,
                ),
              if (isVideo && message.videoUrl != null)
                VideoMessageWidget(
                  videoUrl: message.videoUrl!,
                  caption: message.caption,
                ),
              if (message.messageType == 'voice' && message.voiceUrl != null)
                VoiceMessageBubbleWidget(
                  voiceUrl: message.voiceUrl!,
                  isMe: isMe,
                  timestamp: message.createdAt,
                  isRead: message.isRead,
                ),

              if ((isImage || isVideo) && displayDraft.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4, right: 12, bottom: 2),
                  child: timeAndStatus(
                    isMe ? AppColors.white70 : AppColors.black54,
                    isMe ? AppColors.white70 : AppColors.black54,
                  ),
                ),
              if (displayDraft.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    spacing: 10,
                    runSpacing: 2,
                    children: [
                      Text(
                        displayDraft,
                        textDirection: ChatHelper.getTextDirection(
                          displayDraft,
                        ),
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium!.copyWith(
                          color: isMe ? AppColors.white : AppColors.black87,
                          fontSize: 15,
                          height: 1.3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      timeAndStatus(
                        isMe ? AppColors.white70 : AppColors.black54,
                        isMe ? AppColors.white70 : AppColors.black54,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        if (hasReaction)
          Positioned(
            bottom: -12,
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
                color: Theme.of(
                  context,
                ).scaffoldBackgroundColor.withValues(alpha: 0.75),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                  ),
                ],
              ),

              child: Text(
                message.reaction!,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium!.copyWith(fontSize: 14),
              ),
            ),
          ),
      ],
    );
  }
}
