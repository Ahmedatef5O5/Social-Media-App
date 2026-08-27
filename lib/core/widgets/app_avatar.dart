import 'package:flutter/material.dart';
import 'package:social_media_app/core/constants/app_images.dart';
import 'package:social_media_app/core/widgets/cached_cloudinary_image.dart';

class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final Color? borderColor;
  final double borderWidth;
  final String? heroTag;
  final VoidCallback? onTap;
  final String? cacheKey;
  final WidgetBuilder? placeholder;

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.size = 36,
    this.borderColor,
    this.borderWidth = 2.0,
    this.heroTag,
    this.onTap,
    this.cacheKey,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatar = _buildAvatar(context);

    if (heroTag != null) {
      avatar = Hero(tag: heroTag!, child: avatar);
    }

    if (onTap != null) {
      avatar = GestureDetector(onTap: onTap, child: avatar);
    }

    return avatar;
  }

  Widget _buildAvatar(BuildContext context) {
    final hasBorder = borderColor != null;

    Widget image = ClipOval(child: _buildImage(context));

    if (hasBorder) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor!, width: borderWidth),
        ),
        child: image,
      );
    }

    return SizedBox(width: size, height: size, child: image);
  }

  Widget _buildImage(BuildContext context) {
    final hasUrl = imageUrl != null && imageUrl!.isNotEmpty;

    if (!hasUrl) {
      return Image.asset(
        AppImages.defaultUserImg,
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    }

    return CachedCloudinaryImage(
      secureUrl: imageUrl!,
      width: size,
      height: size,
      fit: BoxFit.cover,
      isAvatar: true,
      placeholder: placeholder,
      errorWidget:
          (_, __) => Image.asset(
            AppImages.defaultUserImg,
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
    );
  }
}
