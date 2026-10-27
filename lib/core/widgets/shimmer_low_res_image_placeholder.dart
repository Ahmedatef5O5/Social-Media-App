import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../cache/utils/cloudinary_url_extensions.dart';
import 'custom_loading_indicator.dart';

class ShimmerLowResImagePlaceholder extends StatelessWidget {
  final String secureUrl;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  const ShimmerLowResImagePlaceholder({
    super.key,
    required this.secureUrl,
    this.width,
    this.height,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lowResUrl = secureUrl.cloudinaryLowResPreviewUrl;

    final shimmerBase = Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[850]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(
        width: width ?? double.infinity,
        height: height ?? double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius,
        ),
      ),
    );

    final shimmerWithLoader = Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        shimmerBase,
        const Center(child: CustomLoadingIndicator(radius: 12)),
      ],
    );

    if (lowResUrl.isEmpty || !lowResUrl.startsWith('http')) {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: SizedBox(
          width: width ?? double.infinity,
          height: height,
          child: shimmerWithLoader,
        ),
      );
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: SizedBox(
        width: width ?? double.infinity,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            shimmerWithLoader,

            CachedNetworkImage(
              imageUrl: lowResUrl,
              width: width ?? double.infinity,
              height: height,
              fit: fit,
              placeholder: (context, url) => shimmerWithLoader,
              errorWidget: (context, url, error) => shimmerWithLoader,
              imageBuilder: (context, imageProvider) {
                return ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Image(
                    image: imageProvider,
                    width: width ?? double.infinity,
                    height: height,
                    fit: fit,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
