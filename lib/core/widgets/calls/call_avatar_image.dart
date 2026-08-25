import 'package:flutter/material.dart';
import '../../constants/app_images.dart';
import '../cached_cloudinary_image.dart';

class CallAvatarImage extends StatelessWidget {
  final String? imageUrl;
  final String fallbackLabel;
  final double diameter;
  final Color borderColor;
  final double borderWidth;
  final List<BoxShadow>? shadows;
  final bool isGroup;

  const CallAvatarImage({
    super.key,
    required this.imageUrl,
    required this.fallbackLabel,
    required this.diameter,
    this.borderColor = Colors.white,
    this.borderWidth = 3,
    this.shadows,
    this.isGroup = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor.withValues(alpha: 0.8),
          width: borderWidth,
        ),
        boxShadow:
            shadows ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 22,
                spreadRadius: 3,
              ),
            ],
      ),
      child: ClipOval(
        child:
            (imageUrl != null && imageUrl!.isNotEmpty)
                ? CachedCloudinaryImage(
                  secureUrl: imageUrl!,
                  fit: BoxFit.cover,
                  isAvatar: true,
                  errorWidget: (_, __) => _fallback(),
                )
                : _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return Center(
      child: Image.asset(
        isGroup ? AppImages.defaultGroupImg : AppImages.defaultUserImg,
        fit: BoxFit.cover,
        width: double.infinity,
      ),
    );
  }
}
