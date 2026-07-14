import 'package:flutter/material.dart';
import 'package:social_media_app/core/widgets/cached_cloudinary_image.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import '../model/sticker_model.dart';
import '../utils/sticker_url_utils.dart';

class StickerThumbnail extends StatelessWidget {
  final StickerModel sticker;
  final BoxFit fit;

  const StickerThumbnail({
    super.key,
    required this.sticker,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final previewUrl = StickerUrlUtils.staticPreviewUrl(
      sticker.imageUrl,
      isAnimated: sticker.isAnimated,
    );

    return Stack(
      children: [
        Positioned.fill(
          child: CachedCloudinaryImage(
            secureUrl: previewUrl,
            fit: fit,
            placeholder: (context) => const CustomLoadingIndicator(),
          ),
        ),
        // if (sticker.isAnimated)
        //   Positioned(
        //     top: 2,
        //     right: 2,
        //     child: Container(
        //       padding: const EdgeInsets.all(2),
        //       decoration: BoxDecoration(
        //         color: Colors.black.withValues(alpha: 0.55),
        //         shape: BoxShape.circle,
        //       ),
        //       child: const Icon(Icons.bolt, size: 11, color: Colors.white),
        //     ),
        //   ),
      ],
    );
  }
}
