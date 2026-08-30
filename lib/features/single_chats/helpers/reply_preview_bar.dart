import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/chat_shared/widgets/reply_preview_thumbnail.dart';
import '../../../core/themes/app_colors.dart';
import '../models/message_model.dart';

class ReplyPreviewBar extends StatelessWidget {
  final MessageModel replyTo;
  final bool isMe;
  final String senderName;
  final VoidCallback onCancel;
  const ReplyPreviewBar({
    super.key,
    required this.replyTo,
    required this.isMe,
    required this.onCancel,
    required this.senderName,
  });

  String? get _mediaUrl {
    switch (replyTo.messageType) {
      case 'image':
      case 'gif':
      case 'sticker':
        return replyTo.imageUrl;
      case 'video':
        return replyTo.videoUrl;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _previewText();
    final mediaUrl = _mediaUrl;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: Theme.of(context).primaryColor, width: 3),
        ),
      ),
      child: Row(
        children: [
          if (mediaUrl != null) ...[
            ReplyPreviewThumbnail(
              messageType: replyTo.messageType,
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
                  isMe ? 'You' : senderName,
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const Gap(2),
                Text(
                  preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.greyColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.close, size: 18),
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }

  String _previewText() {
    switch (replyTo.messageType) {
      case 'image':
        return '📷 Photo';
      case 'video':
        return '🎥 Video';
      case 'gif':
        return '🖼️ GIF';
      case 'sticker':
        return '🏷️ Sticker';
      case 'voice':
        return '🎤 Voice message';
      case 'file':
        return '📄 ${replyTo.fileName ?? 'File'}';
      default:
        final t = replyTo.caption ?? replyTo.text;
        return t.length > 60 ? '${t.substring(0, 60)}...' : t;
    }
  }
}
