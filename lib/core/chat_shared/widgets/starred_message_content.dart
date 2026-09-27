import 'package:flutter/material.dart';
import 'package:social_media_app/core/attachment/widgets/file_message_bubble.dart';
import 'package:social_media_app/core/helpers/chat_helper.dart';
import 'package:social_media_app/core/link/widgets/message_link_preview.dart';
import 'package:social_media_app/features/gifs/widgets/gif_message_bubble.dart';
import 'package:social_media_app/features/single_chats/widgets/image_message_widget.dart';
import 'package:social_media_app/features/single_chats/widgets/story_reply_preview_bubble.dart';
import 'package:social_media_app/features/single_chats/widgets/video_message_widget.dart';
import 'package:social_media_app/features/single_chats/widgets/voice_message_bubble_widget.dart';
import 'package:social_media_app/features/stickers/widgets/sticker_message_bubble.dart';
import '../models/starred_message_entry.dart';

const double _kStarredVoiceBubbleWidth = 260;

class StarredMessageContent extends StatelessWidget {
  final StarredMessageEntry entry;

  const StarredMessageContent({super.key, required this.entry});

  bool get _isImage => entry.messageType == 'image';
  bool get _isVideo => entry.messageType == 'video';
  bool get _isGif => entry.messageType == 'gif';
  bool get _isSticker => entry.messageType == 'sticker';
  bool get _isVoice => entry.messageType == 'voice';
  bool get _isFile => entry.messageType == 'file';
  bool get _isText => entry.messageType == 'text';
  bool get _isStickerOrGif => _isGif || _isSticker;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final maxBubbleWidth = MediaQuery.sizeOf(context).width * 0.72;

    final bubbleColor =
        entry.isMe
            ? Theme.of(context).primaryColor
            : (isDarkMode
                ? Theme.of(context).colorScheme.surfaceContainerHigh
                : Colors.grey.shade200);

    final EdgeInsetsGeometry bubblePadding =
        _isStickerOrGif
            ? EdgeInsets.zero
            : (_isImage || _isVideo)
            ? const EdgeInsets.all(3)
            : const EdgeInsets.symmetric(horizontal: 10, vertical: 8);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxBubbleWidth,
        minWidth:
            _isVoice
                ? (_kStarredVoiceBubbleWidth > maxBubbleWidth
                    ? maxBubbleWidth
                    : _kStarredVoiceBubbleWidth)
                : (_isImage || _isVideo ? 200 : 48),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (entry.isStoryReply)
            StoryReplyPreviewBubble(
              replyToStoryId: entry.replyToStoryId,
              replyToStoryAuthorId: entry.replyToStoryAuthorId,
              replyToStoryType: entry.replyToStoryType,
              replyToStoryMediaUrl: entry.replyToStoryMediaUrl,
              replyToStoryText: entry.replyToStoryText,
              replyToStoryBgColor: entry.replyToStoryBgColor,
              replyToStoryDurationSeconds: entry.replyToStoryDurationSeconds,
              isMe: entry.isMe,
              onColoredBubble: entry.isMe && !_isStickerOrGif,
            ),
          Container(
            padding: bubblePadding,
            decoration: BoxDecoration(
              color: _isStickerOrGif ? Colors.transparent : bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(entry.isMe ? 20 : 4),
                bottomRight: Radius.circular(entry.isMe ? 4 : 20),
              ),
            ),
            child:
                _isStickerOrGif
                    ? _buildBody(context, isDarkMode)
                    : ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(entry.isMe ? 18 : 4),
                        bottomRight: Radius.circular(entry.isMe ? 4 : 18),
                      ),
                      child: _buildBody(context, isDarkMode),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isDarkMode) {
    final textColor =
        entry.isMe
            ? Colors.white
            : (isDarkMode ? Colors.white : Colors.black87);
    final hasCaption =
        entry.caption != null && entry.caption!.trim().isNotEmpty;

    if (_isImage) {
      return IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 260,
              height: 240,
              child:
                  entry.imageUrl != null
                      ? ImageMessageWidget(
                        imageUrl: entry.imageUrl!,
                        caption: entry.caption,
                        isMe: entry.isMe,
                        fileSizeBytes: entry.fileSizeBytes,
                      )
                      : const SizedBox.shrink(),
            ),
            if (hasCaption)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
                child: Text(
                  entry.caption!,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  textDirection: ChatHelper.getTextDirection(entry.caption!),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14.5,
                    height: 1.3,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    if (_isVideo) {
      return IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 260,
              height: 190,
              child:
                  entry.videoUrl != null
                      ? VideoMessageWidget(
                        videoUrl: entry.videoUrl!,
                        caption: entry.caption,
                        isMe: entry.isMe,
                        fileSizeBytes: entry.fileSizeBytes,
                        durationSeconds: entry.durationSeconds,
                      )
                      : const SizedBox.shrink(),
            ),
            if (hasCaption)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
                child: Text(
                  entry.caption!,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  textDirection: ChatHelper.getTextDirection(entry.caption!),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14.5,
                    height: 1.3,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    if (_isVoice && entry.voiceUrl != null && entry.voiceUrl!.isNotEmpty) {
      return SizedBox(
        width: _kStarredVoiceBubbleWidth,
        child: VoiceMessageBubbleWidget(
          voiceUrl: entry.voiceUrl!,
          isMe: entry.isMe,
          timestamp: entry.createdAt,
          isRead: entry.isRead,
          isUploading: false,
          initialDurationSeconds: entry.durationSeconds,
        ),
      );
    }

    if (_isGif) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 190,
          height: 190,
          child:
              entry.imageUrl != null
                  ? GifMessageBubble(url: entry.imageUrl!, isMe: entry.isMe)
                  : const SizedBox.shrink(),
        ),
      );
    }

    if (_isSticker) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 145,
          height: 145,
          child:
              entry.imageUrl != null
                  ? StickerMessageBubble(url: entry.imageUrl!)
                  : const SizedBox.shrink(),
        ),
      );
    }

    if (_isFile) {
      return FileMessageBubble(
        fileUrl: entry.fileUrl ?? '',
        fileName: entry.fileName,
        fileSizeBytes: entry.fileSizeBytes,
        isMe: entry.isMe,
        isUploading: false,
      );
    }

    if (_isText) {
      final displayText =
          (entry.caption != null && entry.caption!.isNotEmpty)
              ? entry.caption!
              : entry.text;
      return MessageLinkPreview(
        text: displayText,
        isMe: entry.isMe,
        textWidget: Text(
          displayText,
          maxLines: 6,
          overflow: TextOverflow.ellipsis,
          textDirection: ChatHelper.getTextDirection(displayText),
          style: TextStyle(color: textColor, fontSize: 14.5, height: 1.3),
        ),
      );
    }

    return _FallbackPreviewRow(entry: entry, textColor: textColor);
  }
}

class _FallbackPreviewRow extends StatelessWidget {
  final StarredMessageEntry entry;
  final Color textColor;
  const _FallbackPreviewRow({required this.entry, required this.textColor});

  IconData get _leadingIcon {
    switch (entry.messageType) {
      case 'voice':
        return Icons.mic_none_rounded;
      case 'call':
        return Icons.call_outlined;
      default:
        return Icons.chat_bubble_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Icon(
            _leadingIcon,
            size: 16,
            color: textColor.withValues(alpha: 0.85),
          ),
        ),
        Flexible(
          child: Text(
            entry.previewText,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: textColor, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
