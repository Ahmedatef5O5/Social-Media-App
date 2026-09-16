import 'package:flutter/material.dart';
import '../../../core/helpers/bidi_text_helper.dart';
import '../models/ai_chat_message.dart';

class AiChatReplyPreviewBar extends StatelessWidget {
  final AiChatMessage message;
  final VoidCallback onCancel;
  final VoidCallback onTap;

  const AiChatReplyPreviewBar({
    super.key,
    required this.message,
    required this.onCancel,
    required this.onTap,
  });

  String get _senderLabel =>
      message.isMe ? 'You' : (message.model?.fullLabel ?? 'Syncra');

  IconData? get _mediaIcon {
    switch (message.mediaType) {
      case AiChatMediaType.image:
        return Icons.photo_rounded;
      case AiChatMediaType.video:
        return Icons.videocam_rounded;
      case AiChatMediaType.voice:
        return Icons.mic_rounded;
      case AiChatMediaType.file:
        return Icons.insert_drive_file_rounded;
      case AiChatMediaType.none:
        return null;
    }
  }

  String get _mediaLabel {
    switch (message.mediaType) {
      case AiChatMediaType.image:
        return 'Photo';
      case AiChatMediaType.video:
        return 'Video';
      case AiChatMediaType.voice:
        final seconds = message.durationSeconds;
        return seconds == null
            ? 'Voice message'
            : 'Voice message · ${_formatDuration(seconds)}';
      case AiChatMediaType.file:
        return message.fileName ?? 'File';
      case AiChatMediaType.none:
        return 'Message';
    }
  }

  String get _previewText {
    final trimmed = message.text.trim();
    if (trimmed.isNotEmpty) {
      return trimmed.length > 90 ? '${trimmed.substring(0, 90)}…' : trimmed;
    }
    return _mediaLabel;
  }

  bool get _hasThumbnail {
    final url = message.mediaUrl;
    if (url == null || !url.startsWith('http')) return false;
    return message.mediaType == AiChatMediaType.image ||
        message.mediaType == AiChatMediaType.video;
  }

  static String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final rest = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${rest.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final icon = _mediaIcon;
    final previewText = _previewText;

    final bodyDirection = BidiTextHelper.detectDirection(previewText);
    final bodyAlign = BidiTextHelper.alignFor(bodyDirection);
    final titleDirection = BidiTextHelper.detectDirection(_senderLabel);
    final titleAlign = BidiTextHelper.alignFor(titleDirection);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Directionality(
          textDirection: bodyDirection,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 3, color: primary),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _senderLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: titleAlign,
                          textDirection: titleDirection,
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (icon != null) ...[
                              Icon(
                                icon,
                                size: 13,
                                color: Colors.white.withValues(alpha: 0.65),
                              ),
                              const SizedBox(width: 5),
                            ],
                            Expanded(
                              child: Text(
                                previewText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: bodyAlign,
                                textDirection: bodyDirection,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.65),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (_hasThumbnail)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        message.mediaUrl!,
                        width: 34,
                        height: 34,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 38),
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  onPressed: onCancel,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
