import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:social_media_app/core/mentions/widgets/mention_rich_text.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import '../../../core/attachment/widgets/file_message_bubble.dart';
import '../../../core/link/widgets/message_link_preview.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../gifs/widgets/gif_message_bubble.dart';
import '../../home/cubits/home_cubit/home_cubit.dart';
import '../../single_chats/widgets/image_message_widget.dart';
import '../../single_chats/widgets/video_message_widget.dart';
import '../../stickers/widgets/sticker_message_bubble.dart';
import '../cubit/group_details_cubit/group_details_cubit.dart';
import '../models/groupe_message_model.dart';
import 'group_message_reply_preview.dart';
import 'group_time_row.dart';
import 'group_voice_message_bubble.dart';

class GroupRegularMessageContent extends StatelessWidget {
  final GroupMessageModel message;
  final bool isMe;
  final bool isUploading;
  final Color textColor;
  final Color primary;
  final ItemScrollController itemScrollController;

  const GroupRegularMessageContent({
    super.key,
    required this.message,
    required this.isMe,
    required this.isUploading,
    required this.textColor,
    required this.primary,
    required this.itemScrollController,
  });

  @override
  Widget build(BuildContext context) {
    final isImage = message.messageType == 'image';
    final isVideo = message.messageType == 'video';
    final isGif = message.messageType == 'gif';
    final isSticker = message.messageType == 'sticker';
    final isVoice = message.messageType == 'voice';
    final isFile = message.messageType == 'file';
    final currentUserId = SupabaseProvider.id;
    final displayText = message.caption ?? message.text;
    final timeWidget = GroupTimeRow(message: message, isMe: isMe);

    final hasReactions = message.reactions.isNotEmpty;
    final bubbleMaxWidth = MediaQuery.of(context).size.width * 0.75;
    double minBubbleWidth = 0;
    if (hasReactions) {
      final uniqueEmojis = message.reactions.values.toSet().length;
      minBubbleWidth = (uniqueEmojis * 36.0) + 24.0;
      minBubbleWidth = minBubbleWidth.clamp(0.0, bubbleMaxWidth);
    }

    return IntrinsicWidth(
      child: Container(
        constraints: BoxConstraints(minWidth: minBubbleWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.replyToMessageId != null)
              GestureDetector(
                onTap: () {
                  final cubit = context.read<GroupDetailsCubit>();
                  if (itemScrollController.isAttached) {
                    cubit.scrollToMessage(
                      messageId: message.replyToMessageId!,
                      itemScrollController: itemScrollController,
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: GroupReplyBubblePreview(
                    message: message,
                    isMe: isMe,
                    currentUserId: currentUserId,
                  ),
                ),
              ),

            if (!isMe)
              Padding(
                padding: EdgeInsets.only(
                  bottom: 4,
                  left: isVideo || isImage || isGif || isSticker ? 6 : 0,
                ),
                child: Text(
                  message.senderName,
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),

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
            if (isVoice)
              GroupVoiceMessageBubbleWidget(
                voiceUrl: message.voiceUrl ?? '',
                isMe: isMe,
                timestamp: message.createdAt,
                isUploading: isUploading,
                initialDurationSeconds: message.durationSeconds,
              ),
            if (isFile && message.fileUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: FileMessageBubble(
                  fileUrl: message.fileUrl!,
                  fileName: message.fileName,
                  fileSizeBytes: message.fileSizeBytes,
                  isMe: isMe,
                ),
              ),
            if (displayText.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(
                  top: (isImage || isVideo || isGif || isSticker) ? 8 : 0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.messageType == 'text')
                      MessageLinkPreview(
                        text: displayText,
                        isMe: isMe,
                        textWidget: _MentionRichText(
                          displayText: displayText,
                          textColor: textColor,
                          isMe: isMe,
                          primary: primary,
                          bubbleMaxWidth: bubbleMaxWidth,
                          message: message,
                        ),
                      )
                    else
                      _MentionRichText(
                        displayText: displayText,
                        textColor: textColor,
                        isMe: isMe,
                        primary: primary,
                        bubbleMaxWidth: bubbleMaxWidth,
                        message: message,
                      ),
                    Align(alignment: Alignment.bottomRight, child: timeWidget),
                  ],
                ),
              ),

            if (displayText.isEmpty && (isImage || isVideo || isFile))
              Align(alignment: Alignment.bottomRight, child: timeWidget),
          ],
        ),
      ),
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
        child: GroupTimeRow(message: message, isMe: isMe),
      ),
    );
  }
}

class _MentionRichText extends StatelessWidget {
  const _MentionRichText({
    required this.displayText,
    required this.textColor,
    required this.isMe,
    required this.primary,
    required this.bubbleMaxWidth,
    required this.message,
  });

  final String displayText;
  final Color textColor;
  final bool isMe;
  final Color primary;
  final double bubbleMaxWidth;
  final GroupMessageModel message;

  @override
  Widget build(BuildContext context) {
    return MentionRichText(
      text: displayText,
      style: TextStyle(color: textColor, fontSize: 15, height: 1.3),
      mentionColor: isMe ? Colors.white : primary,
      maxTextWidth: bubbleMaxWidth,
      mentions: message.mentions,
      onMentionTap: (userId, name) {
        final currentUserId = SupabaseProvider.idOrNull;
        final navController = context.read<HomeCubit>().navController;

        if (userId == currentUserId) {
          if (navController != null) {
            Navigator.of(context).popUntil((route) => route.isFirst);
            navController.jumpToTab(3);
          }
        } else {
          Navigator.of(
            context,
            rootNavigator: true,
          ).pushNamed(AppRoutes.profileViewRoute, arguments: userId);
        }
      },
    );
  }
}
