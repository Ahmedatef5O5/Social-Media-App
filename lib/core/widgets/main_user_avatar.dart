import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import '../constants/app_images.dart';

class MainUserAvatar extends StatelessWidget {
  final String? imageUrl;
  final double? size;
  final bool showBorder;
  const MainUserAvatar({
    super.key,
    this.imageUrl,
    this.size = 36,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size ?? 31,
      height: size ?? 31,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border:
            showBorder
                ? Border.all(
                  color: Theme.of(context).primaryColor.withValues(alpha: .8),
                  width: 2.2,
                )
                : null,
      ),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl ?? AppImages.defaultUserImg,
          fit: BoxFit.cover,
          placeholder:
              (context, url) =>
                  CustomLoadingIndicator(radius: size != null ? size! / 4 : 10),

          errorWidget:
              (context, url, error) =>
                  Image.network(AppImages.defaultUserImg, fit: BoxFit.cover),
        ),
      ),
    );
  }
}
