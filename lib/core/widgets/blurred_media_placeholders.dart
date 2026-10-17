import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:social_media_app/core/cache/utils/cloudinary_url_extensions.dart';
import 'package:social_media_app/core/widgets/cached_cloudinary_image.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';

class BlurredImagePlaceholder extends StatelessWidget {
  final String secureUrl;
  final BorderRadius? borderRadius;

  const BlurredImagePlaceholder({
    super.key,
    required this.secureUrl,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lowResUrl = secureUrl.cloudinaryLowResPreviewUrl;

    final shimmerBase = Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[850]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius,
        ),
      ),
    );

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          shimmerBase,

          if (lowResUrl.isNotEmpty && lowResUrl.startsWith('http'))
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Image.network(
                lowResUrl,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),

          Center(
            child: CustomLoadingIndicator(
              radius: 13,
              color: isDark ? Colors.white70 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }
}

class BlurredVideoPlaceholder extends StatelessWidget {
  final String videoUrl;
  final Uint8List? localThumbnailBytes;
  final BorderRadius? borderRadius;

  const BlurredVideoPlaceholder({
    super.key,
    required this.videoUrl,
    this.localThumbnailBytes,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final networkThumbnailUrl = videoUrl.cloudinaryVideoThumbnailUrl;

    final shimmerBase = Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[850]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius,
        ),
      ),
    );

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          shimmerBase,
          if (localThumbnailBytes != null)
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Image.memory(
                localThumbnailBytes!,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
            )
          else if (networkThumbnailUrl != null)
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: CachedCloudinaryImage(
                secureUrl: networkThumbnailUrl,
                fit: BoxFit.cover,
                placeholder: (_) => shimmerBase,
                errorWidget: (_, __) => const SizedBox.shrink(),
              ),
            ),

          Center(
            child: CustomLoadingIndicator(
              radius: 14,
              color: isDark ? Colors.white70 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }
}

class CompactBlurredImagePlaceholder extends StatelessWidget {
  final String secureUrl;

  const CompactBlurredImagePlaceholder({super.key, required this.secureUrl});

  @override
  Widget build(BuildContext context) {
    final lowResUrl = secureUrl.cloudinaryLowResPreviewUrl;

    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.black12),
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Image.network(
            lowResUrl,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

class CompactBlurredVideoPlaceholder extends StatelessWidget {
  final String videoUrl;
  final Uint8List? localThumbnailBytes;

  const CompactBlurredVideoPlaceholder({
    super.key,
    required this.videoUrl,
    this.localThumbnailBytes,
  });

  @override
  Widget build(BuildContext context) {
    final networkThumbnailUrl = videoUrl.cloudinaryVideoThumbnailUrl;

    Widget? thumbnail;
    if (localThumbnailBytes != null) {
      thumbnail = Image.memory(
        localThumbnailBytes!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    } else if (networkThumbnailUrl != null) {
      thumbnail = CachedCloudinaryImage(
        secureUrl: networkThumbnailUrl,
        fit: BoxFit.cover,
        placeholder: (_) => const ColoredBox(color: Colors.black12),
        errorWidget: (_, __) => const ColoredBox(color: Colors.black12),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.black12),
        if (thumbnail != null)
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: thumbnail,
          ),
      ],
    );
  }
}
