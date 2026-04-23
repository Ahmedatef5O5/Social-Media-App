import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:social_media_app/core/widgets/custom_linkify_text.dart';
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final double maxBubbleWidth = MediaQuery.of(context).size.width * 0.70;

    final bool isUploading = widget.isMe && widget.uploadProgress != null;
    final bool isImage = widget.message.messageType == 'image';
    final bool isVideo = widget.message.messageType == 'video';
    final bool isVoice = widget.message.messageType == 'voice';
    final bool isCall = widget.message.messageType == 'call';
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
              color:
                  widget.isMe
                      ? AppColors.white70
                      : Theme.of(context).colorScheme.onSurface,
              fontSize: 9,
            ),
          ),
          if (widget.isMe) ...[
            const Gap(2),
            Icon(
              widget.message.isRead ? Icons.done_all : Icons.done,
              size: 12,
              color:
                  widget.message.isRead
                      ? Colors.green.shade200
                      : Theme.of(context).scaffoldBackgroundColor,
              // color: widget.message.isRead ? Colors.blue[200] : iconColor,
            ),
          ],
        ],
      );
    }

    if (isCall) {
      return _buildCallBubble(
        context,
        timeAndStatus,
        maxBubbleWidth,
        hasReaction,
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
                        : (isDarkMode
                            ? Theme.of(context).colorScheme.surfaceContainerHigh
                            : Colors.grey.shade200)),
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
                      child: SizedBox(
                        width: double.infinity,
                        child: ReplyBubblePreview(
                          replyText: widget.message.replyToText,
                          replyType: widget.message.replyToMessageType,
                          isMe: widget.isMe,
                          message: widget.message,
                          currentUserId:
                              context.read<ChatDetailsCubit>().currentUserId,
                          receiverName:
                              context.read<ChatDetailsCubit>().receiverName,
                        ),
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
                          CustomLinkifyText(
                            text: displayDraft,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,

                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium!.copyWith(
                              color:
                                  widget.isMe
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : (Theme.of(context).colorScheme.onSurface
                                          .withValues(alpha: 0.7)),

                              fontSize: 15,
                              height: 1.3,
                              fontWeight: FontWeight.w500,
                            ),
                            linkStyle: TextStyle(
                              color: widget.isMe ? Colors.black45 : Colors.blue,

                              decorationColor:
                                  widget.isMe ? Colors.black45 : Colors.blue,
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

  Widget _buildCallBubble(
    BuildContext context,
    Widget Function(Color, Color?) timeAndStatus,
    double maxBubbleWidth,
    bool hasReaction,
  ) {
    Map<String, dynamic> callData = {};
    try {
      callData = jsonDecode(widget.message.text) as Map<String, dynamic>;
    } catch (_) {}

    final status = callData['status'] as String? ?? 'ended';
    final callType = callData['call_type'] as String? ?? 'audio';
    final duration = callData['duration'] as String? ?? '';

    final bool isAudio = callType == 'audio';
    final bool isMissed = status == 'rejected' || status == 'missed';

    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final IconData icon =
        isMissed
            ? (isAudio ? Icons.call_missed : Icons.missed_video_call)
            : (isAudio ? Icons.call : Icons.videocam);

    final Color bubbleBg =
        widget.isMe
            ? Theme.of(context).primaryColor.withValues(alpha: 0.95)
            : (isDarkMode
                ? colorScheme.surfaceContainerHigh
                : Colors.grey.shade200);

    final Color textColor =
        widget.isMe
            ? colorScheme.onPrimary
            : colorScheme.onSurface.withValues(alpha: 0.7);
    final Color timeColor =
        widget.isMe
            ? Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8)
            : Theme.of(context).scaffoldBackgroundColor;

    final Color iconColor =
        widget.isMe
            ? colorScheme.onPrimary
            : (isMissed ? Colors.redAccent : Colors.green);

    final Color iconBgColor =
        widget.isMe
            ? Colors.white.withValues(alpha: 0.5)
            : iconColor.withValues(alpha: 0.15);

    String title =
        isMissed
            ? (isAudio ? 'Missed voice call' : 'Missed video call')
            : (isAudio ? 'Voice call' : 'Video call');

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: EdgeInsets.only(top: 2, bottom: hasReaction ? 28 : 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          constraints: BoxConstraints(maxWidth: maxBubbleWidth, minWidth: 180),
          decoration: BoxDecoration(
            color: bubbleBg,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(widget.isMe ? 20 : 4),
              bottomRight: Radius.circular(widget.isMe ? 4 : 20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const Gap(12),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium!.copyWith(
                            color: textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (duration.isNotEmpty && !isMissed) ...[
                          const Gap(2),
                          Text(
                            duration,
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium!.copyWith(
                              color: widget.isMe ? timeColor : null,
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const Gap(6),
              Align(
                alignment: Alignment.bottomRight,
                child: timeAndStatus(timeColor, timeColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
