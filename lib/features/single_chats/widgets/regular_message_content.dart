import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:social_media_app/core/widgets/custom_linkify_text.dart';
import 'package:social_media_app/features/single_chats/cubit/chat_details_cubit/chat_details_cubit.dart';
import 'package:social_media_app/features/single_chats/widgets/image_message_widget.dart';
import 'package:social_media_app/features/single_chats/widgets/reply_preview_widget.dart';
import 'package:social_media_app/features/single_chats/widgets/story_reply_preview_bubble.dart';
import 'package:social_media_app/features/single_chats/widgets/video_message_widget.dart';
import 'package:social_media_app/features/single_chats/widgets/voice_message_bubble_widget.dart';
import '../models/message_model.dart';
import 'message_time_and_status.dart';

class RegularMessageContent extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool isImage;
  final bool isVideo;
  final ItemScrollController itemScrollController;

  const RegularMessageContent({
    super.key,
    required this.message,
    required this.isMe,
    required this.isImage,
    required this.isVideo,
    required this.itemScrollController,
  });

  @override
  Widget build(BuildContext context) {
    final displayDraft = message.caption ?? message.text;

    return IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.replyToMessageId != null)
            GestureDetector(
              onTap: () => _navigateToOriginalMessage(context),
              child: SizedBox(
                width: double.infinity,
                child: ReplyBubblePreview(
                  replyText: message.replyToText,
                  replyType: message.replyToMessageType,
                  isMe: isMe,
                  message: message,
                  currentUserId: context.read<ChatDetailsCubit>().currentUserId,
                  receiverName: context.read<ChatDetailsCubit>().receiverName,
                ),
              ),
            ),
          if (message.isStoryReply)
            StoryReplyPreviewBubble(message: message, isMe: isMe),

          if (isImage)
            SizedBox(
              width: 305,
              height: 320,
              child:
                  message.imageUrl != null
                      ? ImageMessageWidget(
                        imageUrl: message.imageUrl!,
                        caption: message.caption,
                        isMe: isMe,
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
                        isMe: isMe,
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
                  child: MessageTimeAndStatus(message: message, isMe: isMe),
                ),
              ),
            ),
          if (displayDraft.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                top: (isImage || isVideo) ? 8 : 0,
                left: (isImage || isVideo) ? 6 : 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomLinkifyText(
                    text: displayDraft,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      color:
                          isMe
                              ? Theme.of(context).colorScheme.onPrimary
                              : (Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7)),
                      fontSize: 15,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                    ),
                    linkStyle: TextStyle(
                      color: isMe ? Colors.black45 : Colors.blue,
                      decorationColor: isMe ? Colors.black45 : Colors.blue,
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: MessageTimeAndStatus(message: message, isMe: isMe),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _navigateToOriginalMessage(BuildContext context) {
    final replyId = message.replyToMessageId;
    if (replyId == null) return;
    final cubit = context.read<ChatDetailsCubit>();

    if (itemScrollController.isAttached) {
      cubit.scrollToMessage(
        messageId: replyId,
        itemScrollController: itemScrollController,
      );
    } else {
      debugPrint("Controller is not attached to any list");
    }
  }
}
