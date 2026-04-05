import 'dart:ui';
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
  final double? uploadProgress;
  const MessageContentContainer({
    super.key,
    required this.message,
    required this.isMe,
    this.uploadProgress,
  });

  @override
  Widget build(BuildContext context) {
    final bool isUploading =
        isMe && uploadProgress != null && uploadProgress! < 1.0;
    final bool isImage = message.messageType == 'image';
    final bool isVideo = message.messageType == 'video';
    final bool isVoice = message.messageType == 'voice';
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
              (isImage || isVideo)
                  ? const EdgeInsets.all(3)
                  : const EdgeInsets.only(
                    left: 10,
                    right: 10,
                    bottom: 8,
                    top: 6,
                  ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.70,
            minWidth:
                (isImage || isVideo)
                    ? 200
                    : isVoice
                    ? 280
                    : 40,
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
              BoxShadow(color: AppColors.grey1.withValues(alpha: 0.8)),
            ],
          ),
          child: IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isImage)
                  SizedBox(
                    width: 305,
                    height: 200,
                    child:
                        message.imageUrl != null
                            ? ImageMessageWidget(
                              imageUrl: message.imageUrl!,
                              caption: message.caption,
                            )
                            : const SizedBox.shrink(),
                  ),
                if (isVideo)
                  SizedBox(
                    height: 200,
                    width: 280,
                    child:
                        message.videoUrl != null
                            ? VideoMessageWidget(
                              videoUrl: message.videoUrl!,
                              caption: message.caption,
                            )
                            : const SizedBox.shrink(),
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
                    padding: const EdgeInsets.only(top: 4, right: 8, bottom: 2),
                    child: SizedBox(
                      width: double.infinity,
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: timeAndStatus(
                          isMe ? AppColors.white70 : AppColors.black54,
                          isMe ? AppColors.white70 : AppColors.black54,
                        ),
                      ),
                    ),
                  ),
                if (displayDraft.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: (isImage || isVideo) ? 8 : 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                        Align(
                          alignment: Alignment.bottomRight,
                          child: timeAndStatus(
                            isMe ? AppColors.white70 : AppColors.black54,
                            isMe ? AppColors.white70 : AppColors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),

        if (isUploading)
          // if (true)
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(
                top: 2,
                left: 0,
                right: 0,
                bottom: hasReaction ? 28 : 2,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 0),
                  bottomRight: Radius.circular(isMe ? 0 : 20),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.35),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      width: 50,
                                      height: 50,
                                      child: CircularProgressIndicator(
                                        value: 1.0,
                                        strokeWidth: 3,
                                        color: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 50,
                                      height: 50,
                                      child: CircularProgressIndicator(
                                        value: uploadProgress,
                                        strokeWidth: 3,
                                        color: Colors.white,
                                        strokeCap: StrokeCap.round,
                                      ),
                                    ),
                                    const Gap(10),
                                    Text(
                                      "${(uploadProgress! * 100).toInt()}%",
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium!.copyWith(
                                        color: Colors.white,
                                        // color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Roboto',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
