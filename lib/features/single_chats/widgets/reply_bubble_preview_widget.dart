import 'package:flutter/material.dart';
import '../../../core/cache/utils/cloudinary_url_extensions.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/cached_cloudinary_image.dart';
import '../models/message_model.dart';

class ReplyBubblePreview extends StatelessWidget {
  final MessageModel message;
  final String? replyText;
  final String? replyType;
  final bool isMe;
  final String currentUserId;
  final String receiverName;

  const ReplyBubblePreview({
    super.key,
    required this.replyText,
    required this.replyType,
    required this.isMe,
    required this.message,
    required this.currentUserId,
    required this.receiverName,
  });

  static const double _thumbnailSize = 40;

  String _fallbackLabel() {
    switch (replyType) {
      case 'image':
        return '📷 Photo';
      case 'video':
        return '🎥 Video';
      case 'voice':
        return '🎤 Voice message';
      case 'file':
        return '📄 ${message.fileName ?? 'File'}';
      case 'gif':
        return '🖼️ GIF';
      case 'sticker':
        return '🏷️ Sticker';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String senderName =
        message.replyToSenderId == currentUserId ? 'You' : receiverName;

    final String displayText =
        (replyText != null && replyText!.isNotEmpty)
            ? replyText!
            : _fallbackLabel();

    // Nothing to show at all (e.g. deleted/unresolvable original message).
    if (displayText.isEmpty && message.replyToMediaUrl == null) {
      return const SizedBox.shrink();
    }

    final bool hasThumbnail =
        message.replyToMediaUrl != null &&
        (replyType == 'image' || replyType == 'video');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      child: IntrinsicHeight(
        child: ClipRRect(
          borderRadius: BorderRadiusDirectional.all(Radius.circular(8)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                color: isMe ? Colors.white60 : Theme.of(context).primaryColor,
              ),

              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isMe
                            ? Colors.white.withValues(alpha: 0.2)
                            : Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.08),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              senderName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color:
                                    isMe
                                        ? Colors.white.withValues(alpha: 0.9)
                                        : Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              displayText,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    isMe ? Colors.white70 : AppColors.greyColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (hasThumbnail) ...[
                        const SizedBox(width: 8),
                        _buildThumbnail(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    final url = message.replyToMediaUrl!;
    final displayUrl =
        replyType == 'video' ? (url.cloudinaryVideoThumbnailUrl ?? url) : url;

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: _thumbnailSize,
        height: _thumbnailSize,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedCloudinaryImage(
              secureUrl: displayUrl,
              width: _thumbnailSize,
              height: _thumbnailSize,
              fit: BoxFit.cover,
              errorWidget:
                  (context, error) => Container(color: Colors.grey.shade400),
            ),
            if (replyType == 'video')
              const Center(
                child: Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }
}