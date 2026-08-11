import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:social_media_app/core/cache/utils/cloudinary_url_extensions.dart';
import 'package:social_media_app/core/widgets/cached_cloudinary_image.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';

class BlurredImagePlaceholder extends StatelessWidget {
  final String secureUrl;

  const BlurredImagePlaceholder({super.key, required this.secureUrl});

  @override
  Widget build(BuildContext context) {
    final lowResUrl = secureUrl.cloudinaryLowResPreviewUrl;

    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.black),
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Image.network(
            lowResUrl,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
        Container(color: Colors.black.withValues(alpha: 0.25)),
        SizedBox.expand(
          child: Image.network(
            lowResUrl,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
        const Center(
          child: CustomLoadingIndicator(radius: 14, color: Colors.white),
        ),
      ],
    );
  }
}

class BlurredVideoPlaceholder extends StatelessWidget {
  final String videoUrl;
  final Uint8List? localThumbnailBytes;

  const BlurredVideoPlaceholder({
    super.key,
    required this.videoUrl,
    this.localThumbnailBytes,
  });

  @override
  Widget build(BuildContext context) {
    final networkThumbnailUrl = videoUrl.cloudinaryVideoThumbnailUrl;
    final hasThumbnail =
        localThumbnailBytes != null || networkThumbnailUrl != null;

    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.black),
        if (localThumbnailBytes != null)
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Image.memory(
              localThumbnailBytes!,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          )
        else if (networkThumbnailUrl != null)
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: CachedCloudinaryImage(
              secureUrl: networkThumbnailUrl,
              fit: BoxFit.cover,
              placeholder: (_) => const SizedBox.shrink(),
              errorWidget: (_, __) => const SizedBox.shrink(),
            ),
          ),
        Container(color: Colors.black.withValues(alpha: 0.25)),
        if (hasThumbnail)
          Center(
            child:
                localThumbnailBytes != null
                    ? Image.memory(
                      localThumbnailBytes!,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    )
                    : CachedCloudinaryImage(
                      secureUrl: networkThumbnailUrl!,
                      fit: BoxFit.contain,
                      placeholder: (_) => const SizedBox.shrink(),
                      errorWidget: (_, __) => const SizedBox.shrink(),
                    ),
          ),
        const Center(
          child: CustomLoadingIndicator(radius: 14, color: Colors.white),
        ),
      ],
    );
  }
}
