import 'package:flutter/material.dart';
import '../../widgets/custom_loading_indicator.dart';

class MediaLoadingPlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final bool isError;

  const MediaLoadingPlaceholder({
    super.key,
    this.width,
    this.height,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Center(
        child:
            isError
                ? Icon(
                  Icons.image_not_supported_rounded,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 26,
                )
                : const CustomLoadingIndicator(color: Colors.white),
      ),
    );
  }
}
