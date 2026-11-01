import 'package:flutter/material.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/widgets/cached_cloudinary_image.dart';

/// Rounded-square group avatar with the default placeholder fallback.
class GroupSquareAvatar extends StatelessWidget {
  final String? url;
  final double size;
  final double radius;

  const GroupSquareAvatar({
    super.key,
    required this.url,
    this.size = 52,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final has = url != null && url!.isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child:
            has
                ? CachedCloudinaryImage(
                  secureUrl: url!,
                  fit: BoxFit.cover,
                  isAvatar: true,
                  errorWidget:
                      (_, __) => Image.asset(
                        AppImages.defaultGroupImg,
                        fit: BoxFit.cover,
                      ),
                )
                : Image.asset(AppImages.defaultGroupImg, fit: BoxFit.cover),
      ),
    );
  }
}
