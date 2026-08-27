import 'package:flutter/material.dart';
import 'package:social_media_app/core/widgets/cached_cloudinary_image.dart';
import '../../constants/app_images.dart';
import '../../themes/app_colors.dart';

class AvatarStack extends StatelessWidget {
  final List<String> imageUrls;
  final int maxVisible;
  final double avatarSize;
  final double overlapOffset;

  const AvatarStack({
    super.key,
    required this.imageUrls,
    this.maxVisible = 8,
    this.avatarSize = 26,
    this.overlapOffset = 18,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();

    final int total = imageUrls.length;
    final bool hasOverflow = total > maxVisible;
    final int visibleCount = hasOverflow ? maxVisible : total;
    final int overflowCount = total - maxVisible;
    final int circlesCount = visibleCount + (hasOverflow ? 1 : 0);
    final double stackWidth = (circlesCount - 1) * overlapOffset + avatarSize;

    final borderColor = Theme.of(context).scaffoldBackgroundColor;

    return SizedBox(
      height: avatarSize,
      width: stackWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ...List.generate(visibleCount, (index) {
            final imageUrl = imageUrls[index];
            final bool isNetworkImage =
                imageUrl.isNotEmpty &&
                imageUrl.startsWith('http') &&
                imageUrl != 'asset:default';

            return Positioned(
              left: index * overlapOffset,
              child: _AvatarCircle(
                size: avatarSize,
                borderColor: borderColor,
                child:
                    isNetworkImage
                        ? CachedCloudinaryImage(
                          secureUrl: imageUrl,
                          fit: BoxFit.cover,
                          isAvatar: true,
                          errorWidget:
                              (context, error) => Image.asset(
                                AppImages.defaultUserImg,
                                fit: BoxFit.cover,
                              ),
                        )
                        : Image.asset(
                          AppImages.defaultUserImg,
                          fit: BoxFit.cover,
                        ),
              ),
            );
          }),
          if (hasOverflow)
            Positioned(
              left: visibleCount * overlapOffset,
              child: _AvatarCircle(
                size: avatarSize,
                borderColor: borderColor,
                fillColor: AppColors.grey3,
                child: Center(
                  child: Text(
                    '+$overflowCount',
                    style: TextStyle(
                      fontSize: avatarSize * 0.36,
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey7,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  final double size;
  final Color borderColor;
  final Color? fillColor;
  final Widget child;

  const _AvatarCircle({
    required this.size,
    required this.borderColor,
    this.fillColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fillColor ?? borderColor,
        border: Border.all(color: borderColor, width: 2),
      ),
      child: ClipOval(child: child),
    );
  }
}
