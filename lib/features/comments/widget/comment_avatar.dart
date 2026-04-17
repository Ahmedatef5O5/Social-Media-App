import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_images.dart';

class CommentAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;

  const CommentAvatar({
    super.key,
    required this.imageUrl,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundImage:
          (imageUrl != null && imageUrl!.isNotEmpty)
              ? CachedNetworkImageProvider(imageUrl!)
              : const AssetImage(AppImages.defaultUserImg),
    );
  }
}
