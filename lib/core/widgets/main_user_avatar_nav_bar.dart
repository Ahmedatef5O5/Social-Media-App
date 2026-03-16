import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../constants/app_images.dart';
import '../themes/app_colors.dart';

class MainUserAvatarNavBar extends StatelessWidget {
  final String? imageUrl;

  const MainUserAvatarNavBar({super.key, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 31,
      height: 31,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: .5),
          width: 2.2,
        ),
      ),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl ?? AppImages.defaultUserImg,
          fit: BoxFit.cover,
          placeholder:
              (context, url) => CupertinoActivityIndicator(
                color: Theme.of(context).primaryColor,
              ),
          errorWidget:
              (context, url, error) => Image.network(AppImages.defaultUserImg),
        ),
      ),
    );
  }
}
