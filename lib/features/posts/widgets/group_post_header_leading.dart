import 'package:flutter/material.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/cached_cloudinary_image.dart';

/// Layered avatar for group posts: square group avatar (44, radius 12) with
/// the author's circular avatar (radius 10, 2px card-colored ring) overlapping
/// its bottom-end corner. Each avatar has its own tap target.
class GroupPostHeaderLeading extends StatelessWidget {
  final String? groupAvatarUrl;
  final String? authorImageUrl;
  final VoidCallback? onGroupTap;
  final VoidCallback? onAuthorTap;

  const GroupPostHeaderLeading({
    super.key,
    required this.groupAvatarUrl,
    required this.authorImageUrl,
    this.onGroupTap,
    this.onAuthorTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAvatar = groupAvatarUrl != null && groupAvatarUrl!.isNotEmpty;

    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: onGroupTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 44,
                height: 44,
                child:
                    hasAvatar
                        ? CachedCloudinaryImage(
                          secureUrl: groupAvatarUrl!,
                          fit: BoxFit.cover,
                          isAvatar: true,
                        )
                        : Image.asset(
                          AppImages.defaultGroupImg,
                          fit: BoxFit.cover,
                        ),
              ),
            ),
          ),
          PositionedDirectional(
            bottom: -2,
            end: -2,
            child: GestureDetector(
              onTap: onAuthorTap,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.cardColor, width: 2),
                ),
                child: AppAvatar(imageUrl: authorImageUrl, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
