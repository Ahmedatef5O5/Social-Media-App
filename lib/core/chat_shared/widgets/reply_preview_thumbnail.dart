import 'package:flutter/material.dart';
import '../../cache/utils/cloudinary_url_extensions.dart';
import '../../widgets/blurred_media_placeholders.dart';
import '../../widgets/cached_cloudinary_image.dart';

class ReplyPreviewThumbnail extends StatelessWidget {
  final String messageType;
  final String? mediaUrl;
  final double size;

  const ReplyPreviewThumbnail({
    super.key,
    required this.messageType,
    required this.mediaUrl,
    this.size = 40,
  });

  bool get _hasVisualMedia =>
      mediaUrl != null &&
      mediaUrl!.isNotEmpty &&
      (messageType == 'image' ||
          messageType == 'video' ||
          messageType == 'gif' ||
          messageType == 'sticker');

  @override
  Widget build(BuildContext context) {
    if (!_hasVisualMedia) return const SizedBox.shrink();

    final bool isVideo = messageType == 'video';
    final bool isSticker = messageType == 'sticker';
    final displayUrl =
        isVideo
            ? (mediaUrl!.cloudinaryVideoThumbnailUrl ?? mediaUrl!)
            : mediaUrl!;

    if (isSticker) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: size,
          height: size,
          color: Theme.of(context).primaryColor.withValues(alpha: 0.06),
          padding: const EdgeInsets.all(4),
          child: CachedCloudinaryImage(
            secureUrl: displayUrl,
            fit: BoxFit.contain,
            placeholder: (_) => const SizedBox.shrink(),
            errorWidget: (_, __) => const SizedBox.shrink(),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedCloudinaryImage(
              secureUrl: displayUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              placeholder:
                  (_) =>
                      isVideo
                          ? CompactBlurredVideoPlaceholder(videoUrl: mediaUrl!)
                          : CompactBlurredImagePlaceholder(
                            secureUrl: displayUrl,
                          ),
              errorWidget:
                  (context, error) => Container(color: Colors.grey.shade400),
            ),
            if (isVideo)
              const Center(
                child: Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
