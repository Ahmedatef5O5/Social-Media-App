import 'package:flutter/material.dart';
import 'package:social_media_app/core/constants/app_images.dart';
import 'package:social_media_app/core/widgets/cached_cloudinary_image.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';

class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final Color? borderColor;
  final double borderWidth;
  final bool showOnlineDot;
  final bool isOnline;
  final String? heroTag;
  final VoidCallback? onTap;
  final String? cacheKey;

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.size = 36,
    this.borderColor,
    this.borderWidth = 2.0,
    this.showOnlineDot = false,
    this.isOnline = false,
    this.heroTag,
    this.onTap,
    this.cacheKey,
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

    if (showOnlineDot) {
      avatar = Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(bottom: 0, right: 0, child: _buildOnlineDot(context)),
        ],
      );
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
      placeholder: (_) => CustomLoadingIndicator(radius: size / 7),
      errorWidget:
          (_, __) => Image.asset(
            AppImages.defaultUserImg,
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
    );
  }

  Widget _buildOnlineDot(BuildContext context) {
    final dotSize = (size * 0.28).clamp(8.0, 14.0);

    return Container(
      width: dotSize,
      height: dotSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isOnline ? Colors.green : Colors.grey,
        border: Border.all(
          color: Theme.of(context).scaffoldBackgroundColor,
          width: 1.5,
        ),
      ),
    );
  }
}
