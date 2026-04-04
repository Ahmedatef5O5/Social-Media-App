import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/widgets/custom_loading_indicator.dart';

class UserChatAvatar extends StatelessWidget {
  const UserChatAvatar({super.key, required this.userImgUrl});

  final String? userImgUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      width: 28,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl:
              (userImgUrl != null && userImgUrl!.isNotEmpty)
                  ? userImgUrl!
                  : AppImages.defaultUserImg,
          fit: BoxFit.cover,
          placeholder: (context, url) => const CustomLoadingIndicator(),
          errorWidget: (context, url, error) => const Icon(Icons.person),
          maxWidthDiskCache: 200,
          maxHeightDiskCache: 200,
        ),
      ),
    );
  }
}
