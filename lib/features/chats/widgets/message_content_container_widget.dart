import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:social_media_app/core/helpers/chat_helper.dart';
import 'package:social_media_app/features/chats/cubit/chat_details_cubit/chat_details_cubit.dart';
import 'package:social_media_app/features/chats/widgets/image_message_widget.dart';
import 'package:social_media_app/features/chats/widgets/reply_preview_widget.dart';
import 'package:social_media_app/features/chats/widgets/video_message_widget.dart';
import 'package:social_media_app/features/chats/widgets/voice_message_bubble_widget.dart';
import '../../../core/helpers/formatted_date.dart';
import '../../../core/helpers/modern_circle_progress.dart';
import '../../../core/themes/app_colors.dart';
import '../models/message_model.dart';

class MessageContentContainer extends StatefulWidget {
  final MessageModel message;
  final bool isMe;
  final double? uploadProgress;
  final ItemScrollController itemScrollController;
  const MessageContentContainer({
    super.key,
    required this.message,
    required this.isMe,
    this.uploadProgress,
    required this.itemScrollController,
  });

  @override
  State<MessageContentContainer> createState() =>
      _MessageContentContainerState();
}

class _MessageContentContainerState extends State<MessageContentContainer> {
  @override
  Widget build(BuildContext context) {
    final double maxBubbleWidth = MediaQuery.of(context).size.width * 0.70;

    final bool isUploading = widget.isMe && widget.uploadProgress != null;
    final bool isImage = widget.message.messageType == 'image';
    final bool isVideo = widget.message.messageType == 'video';
    final bool isVoice = widget.message.messageType == 'voice';
    final bool hasReaction =
        widget.message.reaction != null && widget.message.reaction!.isNotEmpty;
    final String displayDraft = widget.message.caption ?? widget.message.text;
    Widget timeAndStatus(Color textColor, Color? iconColor) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.ltr,
        children: [
          Text(
            FormattedDate.getMessageTime(widget.message.createdAt),
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              color: widget.isMe ? AppColors.white70 : AppColors.black54,
              fontSize: 9,
            ),
          ),
          if (widget.isMe) ...[
            const Gap(2),
            Icon(
              widget.message.isRead ? Icons.done_all : Icons.done,
              size: 12,
              color: widget.message.isRead ? Colors.blue[200] : iconColor,
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
            maxWidth: maxBubbleWidth,
            minWidth:
                isVoice
                    ? (280 > maxBubbleWidth ? maxBubbleWidth : 280)
                    : (isImage || isVideo ? 200 : 40),
          ),
          decoration: BoxDecoration(
            color:
                (isImage || isVideo) &&
                        (isUploading ||
                            widget.message.imageUrl == null &&
                                widget.message.videoUrl == null)
                    ? AppColors.transparent
                    : (widget.isMe
                        ? Theme.of(context).primaryColor
                        : AppColors.grey3.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(widget.isMe ? 20 : 0),
              bottomRight: Radius.circular(widget.isMe ? 0 : 20),
            ),
            boxShadow:
                isUploading
                    ? []
                    : [
                      BoxShadow(color: AppColors.grey1.withValues(alpha: 0.8)),
                    ],
          ),
          child: Opacity(
            opacity: isUploading ? 0.3 : 1.0,
            child: IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.message.replyToMessageId != null)
                    GestureDetector(
                      onTap: () {
                        _navigateToOriginalMessage(
                          context,
                          widget.message.replyToMessageId!,
                        );
                      },
                      child: ReplyBubblePreview(
                        replyText: widget.message.replyToText,
                        replyType: widget.message.replyToMessageType,
                        isMe: widget.isMe,
                      ),
                    ),
                  if (isImage)
                    SizedBox(
                      width: 305,
                      height: 320,
                      child:
                          widget.message.imageUrl != null
                              ? ImageMessageWidget(
                                imageUrl: widget.message.imageUrl!,
                                caption: widget.message.caption,
                                isMe: widget.isMe,
                              )
                              : const SizedBox.shrink(),
                    ),
                  if (isVideo)
                    SizedBox(
                      height: 200,
                      width: 280,
                      child:
                          widget.message.videoUrl != null
                              ? VideoMessageWidget(
                                videoUrl: widget.message.videoUrl!,
                                caption: widget.message.caption,
                                isMe: widget.isMe,
                              )
                              : const SizedBox.shrink(),
                    ),
                  if (widget.message.messageType == 'voice' &&
                      widget.message.voiceUrl != null)
                    VoiceMessageBubbleWidget(
                      voiceUrl: widget.message.voiceUrl!,
                      isMe: widget.isMe,
                      timestamp: widget.message.createdAt,
                      isRead: widget.message.isRead,
                    ),

                  if ((isImage || isVideo) && displayDraft.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 4,
                        right: 8,
                        bottom: 2,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: timeAndStatus(
                            widget.isMe ? AppColors.white70 : AppColors.black54,
                            widget.isMe ? AppColors.white70 : AppColors.black54,
                          ),
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
                          Text(
                            displayDraft,
                            textDirection: ChatHelper.getTextDirection(
                              displayDraft,
                            ),
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium!.copyWith(
                              color:
                                  widget.isMe
                                      ? AppColors.white
                                      : AppColors.black87,
                              fontSize: 15,
                              height: 1.3,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: timeAndStatus(
                              widget.isMe
                                  ? AppColors.white70
                                  : AppColors.black54,
                              widget.isMe
                                  ? AppColors.white70
                                  : AppColors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        if (isUploading) ...[
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(widget.isMe ? 20 : 0),
                bottomRight: Radius.circular(widget.isMe ? 0 : 20),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.1),
                  child: Center(
                    child: Center(
                      child: ModernCircularProgress(
                        progress: widget.uploadProgress ?? 0.0,
                        size: 110,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: () {
                context.read<ChatDetailsCubit>().cancelUpload(
                  widget.message.id,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).brightness == Brightness.light
                          ? Theme.of(
                            context,
                          ).scaffoldBackgroundColor.withValues(alpha: 1)
                          : Colors.white.withValues(alpha: 1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  size: 18,

                  color:
                      Theme.of(context).brightness == Brightness.light
                          ? Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.5)
                          : Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.95),
                ),
              ),
            ),
          ),
        ],

        if (hasReaction)
          Positioned(
            bottom: -12,
            right: widget.isMe ? 8 : null,
            left: widget.isMe ? null : 8,
            child: Container(
              margin: EdgeInsets.only(
                top: 2,
                bottom:
                    widget.message.reaction != null &&
                            widget.message.reaction!.isNotEmpty
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
                widget.message.reaction!,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium!.copyWith(fontSize: 14),
              ),
            ),
          ),
      ],
    );
  }


  void _navigateToOriginalMessage(BuildContext context, String replyId) {
    final cubit = context.read<ChatDetailsCubit>();

    if (widget.itemScrollController.isAttached) {
      cubit.scrollToMessage(
        messageId: replyId,
        itemScrollController: widget.itemScrollController,
      );
    } else {
      debugPrint("Controller is not attached to any list");
    }
  }
}
