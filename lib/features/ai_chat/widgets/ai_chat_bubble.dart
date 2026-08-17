import 'package:flutter/material.dart';
import '../../../core/attachment/models/media_transfer_state.dart';
import '../../../core/attachment/widgets/file_message_bubble.dart';
import '../../../core/attachment/widgets/media_state_overlay.dart';
import '../../../core/helpers/chat_helper.dart';
import '../../../core/helpers/formatted_date.dart';
import '../../single_chats/widgets/image_message_widget.dart';
import '../../single_chats/widgets/video_message_widget.dart';
import '../../single_chats/widgets/voice_message_bubble_widget.dart';
import '../helpers/ai_model_display.dart';
import '../models/ai_chat_message.dart';
import 'ai_typewriter_text.dart';

class AiChatBubble extends StatelessWidget {
  final AiChatMessage message;
  final VoidCallback? onCancelUpload;
  final VoidCallback? onRetry;
  final VoidCallback? onForward;
  final bool animate;

  const AiChatBubble({
    super.key,
    required this.message,
    this.onCancelUpload,
    this.onRetry,
    this.onForward,
    this.animate = false,
  });

  bool get _isUploading =>
      message.status == AiChatDeliveryStatus.sending &&
      message.mediaType != AiChatMediaType.none;

  BorderRadius _radius(bool isMe) => BorderRadius.only(
    topLeft: const Radius.circular(20),
    topRight: const Radius.circular(20),
    bottomLeft: Radius.circular(isMe ? 20 : 4),
    bottomRight: Radius.circular(isMe ? 4 : 20),
  );

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;
    final hasMedia = message.mediaType != AiChatMediaType.none;
    final hasText = message.text.trim().isNotEmpty;

    final textStyle = TextStyle(
      color: isMe ? Colors.white : Colors.white.withValues(alpha: 0.92),
      fontSize: 15,
      height: 1.35,
      fontWeight: FontWeight.w500,
    );

    final textDirection = ChatHelper.getTextDirection(message.text);
    final textAlign =
        textDirection == TextDirection.rtl ? TextAlign.right : TextAlign.left;

    final bubble = GestureDetector(
      onTap: message.status == AiChatDeliveryStatus.failed ? onRetry : null,
      onLongPress: !isMe ? onForward : null,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.74,
        ),
        padding:
            hasMedia
                ? const EdgeInsets.all(4)
                : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color:
              isMe
                  ? Theme.of(context).primaryColor
                  : Colors.white.withValues(alpha: 0.08),
          borderRadius: _radius(isMe),
          border:
              isMe
                  ? null
                  : Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasMedia) _buildMedia(context, isMe),
            if (hasText)
              Padding(
                padding: EdgeInsets.only(
                  top: hasMedia ? 8 : 0,
                  left: hasMedia ? 6 : 0,
                  right: hasMedia ? 6 : 0,
                ),
                child:
                    isMe
                        ? Text(
                          message.text,
                          style: textStyle,
                          textDirection: textDirection,
                          textAlign: textAlign,
                        )
                        : AiTypewriterText(
                          text: message.text,
                          style: textStyle,
                          animate: animate,
                          textDirection: textDirection,
                          textAlign: textAlign,
                        ),
              ),
            Padding(
              padding: EdgeInsets.only(
                top: 4,
                left: hasMedia && !hasText ? 6 : 0,
              ),
              child: _buildStatusRow(),
            ),
          ],
        ),
      ),
    );

    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _AssistantAvatar(model: message.model),
            const SizedBox(width: 8),
          ],
          Flexible(child: bubble),
        ],
      ),
    );

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder:
          (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, (1 - value) * 10),
              child: child,
            ),
          ),
      child: row,
    );
  }

  String _truncate(String value, int maxLength) {
    if (value.length <= maxLength) return value;
    return '${value.substring(0, maxLength - 1)}…';
  }

  Widget _buildStatusRow() {
    final modelLabel =
        (!message.isMe && message.model != null)
            ? _truncate(message.model!.fullLabel, 30)
            : null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          FormattedDate.getMessageTime(message.createdAt),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 10.5,
          ),
        ),
        if (modelLabel != null) ...[
          Text(
            ' · ',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 10.5,
            ),
          ),
          Text(
            modelLabel,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 10.5,
            ),
          ),
        ],
        if (message.status == AiChatDeliveryStatus.sending) ...[
          const SizedBox(width: 5),
          SizedBox(
            width: 9,
            height: 9,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
        if (message.status == AiChatDeliveryStatus.failed) ...[
          const SizedBox(width: 5),
          const Icon(
            Icons.error_outline_rounded,
            size: 12,
            color: Colors.redAccent,
          ),
        ],
      ],
    );
  }

  Widget _buildMedia(BuildContext context, bool isMe) {
    final transferState =
        _isUploading
            ? MediaTransferState.uploading(message.uploadProgress ?? 0)
            : const MediaTransferState.completed(
              direction: MediaTransferDirection.upload,
            );

    switch (message.mediaType) {
      case AiChatMediaType.image:
        return SizedBox(
          width: 240,
          height: 220,
          child: MediaStateOverlay(
            state: transferState,
            borderRadius: _radius(isMe),
            onCancelTap: onCancelUpload,
            child:
                message.mediaUrl == null
                    ? const SizedBox.shrink()
                    : ImageMessageWidget(
                      imageUrl: message.mediaUrl!,
                      isMe: isMe,
                      fileSizeBytes: message.fileSizeBytes,
                    ),
          ),
        );

      case AiChatMediaType.video:
        return SizedBox(
          width: 240,
          height: 200,
          child: MediaStateOverlay(
            state: transferState,
            borderRadius: _radius(isMe),
            isVideo: true,
            durationSeconds: message.durationSeconds,
            onCancelTap: onCancelUpload,
            child:
                message.mediaUrl == null
                    ? const SizedBox.shrink()
                    : VideoMessageWidget(
                      videoUrl: message.mediaUrl!,
                      isMe: isMe,
                      fileSizeBytes: message.fileSizeBytes,
                      durationSeconds: message.durationSeconds,
                    ),
          ),
        );

      case AiChatMediaType.voice:
        return message.mediaUrl == null
            ? const SizedBox.shrink()
            : VoiceMessageBubbleWidget(
              voiceUrl: message.mediaUrl!,
              isMe: isMe,
              timestamp: message.createdAt,
              isUploading: _isUploading,
              initialDurationSeconds: message.durationSeconds,
            );

      case AiChatMediaType.file:
        return FileMessageBubble(
          fileUrl: message.mediaUrl ?? '',
          fileName: message.fileName,
          fileSizeBytes: message.fileSizeBytes,
          isMe: isMe,
          isUploading: _isUploading,
          uploadProgress: message.uploadProgress,
          onCancelTap: onCancelUpload,
        );

      case AiChatMediaType.none:
        return const SizedBox.shrink();
    }
  }
}

class _AssistantAvatar extends StatelessWidget {
  final AiModelDisplay? model;
  const _AssistantAvatar({this.model});

  @override
  Widget build(BuildContext context) {
    final color = model?.accentColor ?? Theme.of(context).primaryColor;
    final icon = model?.icon ?? Icons.auto_awesome_rounded;
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.18),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Icon(icon, size: 13, color: color),
    );
  }
}
