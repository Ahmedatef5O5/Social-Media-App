import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class MediaLoadingPlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final bool isError;
  final BorderRadius? borderRadius;

  const MediaLoadingPlaceholder({
    super.key,
    this.width,
    this.height,
    this.isError = false,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (isError) {
      return SizedBox(
        width: width,
        height: height,
        child: Center(
          child: Icon(
            Icons.image_not_supported_rounded,
            color: Colors.white.withValues(alpha: 0.7),
            size: 26,
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Shimmer.fromColors(
        baseColor: isDark ? Colors.grey[850]! : Colors.grey[300]!,
        highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
        child: Container(
          width: width ?? double.infinity,
          height: height ?? double.infinity,
          color: Colors.white,
        ),
      ),
    );
  }
}
