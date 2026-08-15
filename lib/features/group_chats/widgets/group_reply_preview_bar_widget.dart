import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/chat_shared/widgets/reply_preview_thumbnail.dart';
import '../../../core/mentions/widgets/mention_rich_text.dart';
import '../models/groupe_message_model.dart';

class GroupReplyPreviewBar extends StatelessWidget {
  final GroupMessageModel reply;
  final VoidCallback onDismiss;

  const GroupReplyPreviewBar({
    super.key,
    required this.reply,
    required this.onDismiss,
  });

  String? get _mediaUrl {
    switch (reply.messageType) {
      case 'image':
      case 'gif':
      case 'sticker':
        return reply.imageUrl;
      case 'video':
        return reply.videoUrl;
      default:
        return null;
    }
  }

  bool get _isPlainText => reply.messageType == 'text';

  String _fallbackLabel() {
    switch (reply.messageType) {
      case 'image':
        return reply.caption?.isNotEmpty == true ? reply.caption! : '📷 Photo';
      case 'video':
        return reply.caption?.isNotEmpty == true ? reply.caption! : '🎥 Video';
      case 'gif':
        return '🖼️ GIF';
      case 'sticker':
        return '🏷️ Sticker';
      case 'voice':
        return '🎤 Voice message';
      case 'file':
        return '📄 ${reply.fileName ?? 'File'}';
      default:
        return reply.text.isNotEmpty ? reply.text : (reply.caption ?? '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mediaUrl = _mediaUrl;

    final Color textColor = Color.alphaBlend(
      isDark ? Colors.white54 : Colors.black54,
      Theme.of(context).scaffoldBackgroundColor,
    );
    final textStyle = TextStyle(color: textColor, fontSize: 12);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: primary, width: 3)),
      ),
      child: Row(
        children: [
          if (mediaUrl != null) ...[
            ReplyPreviewThumbnail(
              messageType: reply.messageType,
              mediaUrl: mediaUrl,
              size: 44,
            ),
            const Gap(8),
          ] else
            const Gap(4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  reply.senderName,
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const Gap(2),
                _isPlainText && reply.text.isNotEmpty
                    ? MentionRichText(
                      text: reply.text,
                      mentions: reply.mentions,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textStyle,
                      mentionColor: primary,
                      onMentionTap: (_, __) {},
                    )
                    : Text(
                      _fallbackLabel(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textStyle,
                    ),
              ],
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.close, size: 18),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}
