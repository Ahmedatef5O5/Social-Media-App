import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:social_media_app/features/single_chats/cubit/chat_details_cubit/chat_details_cubit.dart';
import 'package:social_media_app/features/single_chats/widgets/image_message_widget.dart';
import 'package:social_media_app/features/single_chats/widgets/reply_bubble_preview_widget.dart';
import 'package:social_media_app/features/single_chats/widgets/story_reply_preview_bubble.dart';
import 'package:social_media_app/features/single_chats/widgets/video_message_widget.dart';
import 'package:social_media_app/features/single_chats/widgets/voice_message_bubble_widget.dart';
import '../../../core/attachment/widgets/file_message_bubble.dart';
import '../../../core/chat_shared/widgets/highlighted_linkify_text.dart';
import '../../../core/link/widgets/message_link_preview.dart';
import '../../gifs/widgets/gif_message_bubble.dart';
import '../../stickers/widgets/sticker_message_bubble.dart';
import '../models/message_model.dart';
import 'message_time_and_status.dart';

const double _kVoiceBubbleContentWidth = 260;

class RegularMessageContent extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool isImage;
  final bool isVideo;
  final bool isGif;
  final bool isSticker;
  final ItemScrollController itemScrollController;
  final bool isUploading;
  final double? uploadProgress;
  const RegularMessageContent({
    super.key,
    required this.message,
    required this.isMe,
    required this.isImage,
    required this.isVideo,
    required this.isGif,
    required this.isSticker,
    required this.itemScrollController,
    this.isUploading = false,
    this.uploadProgress,
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
                        fileSizeBytes: message.fileSizeBytes,
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
                        fileSizeBytes: message.fileSizeBytes,
                        durationSeconds: message.durationSeconds,
                      )
                      : const SizedBox.shrink(),
            ),

          if (message.messageType == 'voice' && message.voiceUrl != null)
            SizedBox(
              width: _kVoiceBubbleContentWidth,
              child: VoiceMessageBubbleWidget(
                voiceUrl: message.voiceUrl!,
                isMe: isMe,
                timestamp: message.createdAt,
                isRead: message.isRead,
                initialDurationSeconds: message.durationSeconds,
                isUploading: isUploading,
              ),
            ),

          if (message.messageType == 'file' &&
              (message.fileUrl != null || isUploading))
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: FileMessageBubble(
                fileUrl: message.fileUrl ?? '',
                fileName: message.fileName,
                fileSizeBytes: message.fileSizeBytes,
                isMe: isMe,
                isUploading: isUploading,
                uploadProgress: uploadProgress,
                onCancelTap:
                    () => context.read<ChatDetailsCubit>().cancelUpload(
                      message.id,
                    ),
              ),
            ),

          if ((isImage || isVideo || message.messageType == 'file') &&
              displayDraft.isEmpty)
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
                  if (message.messageType == 'text')
                    MessageLinkPreview(
                      text: displayDraft,
                      isMe: isMe,
                      textWidget: _buildLinkifyText(context, displayDraft),
                    )
                  else
                    _buildLinkifyText(context, displayDraft),

                  Align(
                    alignment: Alignment.bottomRight,
                    child: MessageTimeAndStatus(message: message, isMe: isMe),
                  ),
                ],
              ),
            ),

          if (isGif)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child:
                        message.imageUrl != null
                            ? GifMessageBubble(
                              url: message.imageUrl!,
                              isMe: isMe,
                            )
                            : const SizedBox.shrink(),
                  ),
                ),
                const Gap(2.8),
                Align(
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: _buildMediaTimeOverlay(context),
                ),
              ],
            ),

          if (isSticker)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 150,
                    height: 150,
                    child:
                        message.imageUrl != null
                            ? StickerMessageBubble(url: message.imageUrl!)
                            : const SizedBox.shrink(),
                  ),
                ),
                const Gap(2.8),
                Align(
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: _buildMediaTimeOverlay(context),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLinkifyText(BuildContext context, String text) {
    final searchController = context.read<ChatDetailsCubit>().searchController;

    return ValueListenableBuilder<String>(
      valueListenable: searchController.query,
      builder: (context, query, _) {
        return HighlightedLinkifyText(
          text: text,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          highlightQuery: query,
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
            color:
                isMe
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
            fontSize: 15,
            height: 1.3,
            fontWeight: FontWeight.w500,
          ),
          linkStyle: TextStyle(
            color: isMe ? Colors.black45 : Colors.blue,
            decorationColor: isMe ? Colors.black45 : Colors.blue,
          ),
        );
      },
    );
  }

  Widget _buildMediaTimeOverlay(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.32),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(10),
          topRight: const Radius.circular(10),
          bottomLeft: isMe ? const Radius.circular(10) : Radius.zero,
          bottomRight: isMe ? Radius.zero : const Radius.circular(10),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          brightness: Brightness.dark,
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(onSurface: Colors.white),
        ),
        child: MessageTimeAndStatus(
          message: message,
          isMe: isMe,
          iconColor: Colors.white,
        ),
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
