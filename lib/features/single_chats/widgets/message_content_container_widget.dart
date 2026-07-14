import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:social_media_app/features/single_chats/cubit/chat_details_cubit/chat_details_cubit.dart';
import 'package:social_media_app/features/single_chats/widgets/message_reactions_row_widget.dart';
import '../../../core/helpers/modern_circle_progress.dart';
import '../../../core/themes/app_colors.dart';
import '../models/message_model.dart';
import 'call_message_content.dart';
import 'regular_message_content.dart';

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
    final bool hasReaction = widget.message.reactions.isNotEmpty;

    if (isCall) {
      return CallMessageContent(
        message: widget.message,
        isMe: widget.isMe,
        hasReaction: hasReaction,
        maxBubbleWidth: maxBubbleWidth,
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
            child: RegularMessageContent(
              message: widget.message,
              isMe: widget.isMe,
              isImage: isImage,
              isVideo: isVideo,
              itemScrollController: widget.itemScrollController,
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
                    child: ModernCircularProgress(
                      progress: widget.uploadProgress ?? 0.0,
                      size: 110,
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
            bottom: -2.5,
            right: widget.isMe ? 8 : null,
            left: widget.isMe ? null : 8,
            child: MessageReactionsRow(
              reactions: widget.message.reactions,
              currentUserId: context.read<ChatDetailsCubit>().currentUserId,
              primary: Theme.of(context).primaryColor,
            ),
          ),
      ],
    );
  }
}
