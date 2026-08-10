import 'package:flutter/material.dart';
import 'package:social_media_app/core/widgets/cached_cloudinary_image.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import '../helpers/circle_default_user_img.dart';

class CreateStoryCardWidget extends StatelessWidget {
  static const double cardWidth = 107;
  static const double cardHeight = 160;
  static const double _topRatio = 0.80;

  final String? avatarUrl;
  final bool isUploading;
  final VoidCallback onTap;

  const CreateStoryCardWidget({
    super.key,
    required this.onTap,
    this.avatarUrl,
    this.isUploading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topHeight = cardHeight * _topRatio;
    final bottomHeight = cardHeight - topHeight;
    final screenWidth = MediaQuery.sizeOf(context).width;

    final double addButtonSize = (screenWidth * 0.07).clamp(26.0, 32.0);
    final double borderWidth = (addButtonSize * 0.06).clamp(1.5, 2.0);

    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: SizedBox(
        width: cardWidth,
        height: cardHeight,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(
                  width: cardWidth,
                  height: topHeight,
                  child:
                      avatarUrl == null || avatarUrl!.isEmpty
                          ? CircleDefaultUserImage(
                            theme: theme,
                            cardWidth: cardWidth,
                          )
                          : CachedCloudinaryImage(
                            secureUrl: avatarUrl!,
                            fit: BoxFit.cover,
                            width: cardWidth,
                            height: topHeight,
                            isAvatar: true,
                            placeholder:
                                (_) => Container(color: theme.dividerColor),
                            errorWidget:
                                (_, __) => CircleDefaultUserImage(
                                  theme: theme,
                                  cardWidth: cardWidth,
                                ),
                          ),
                ),

                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 13,
                  height: bottomHeight,
                  child: Container(
                    color: theme.scaffoldBackgroundColor,
                    padding: EdgeInsets.zero,

                    child: Text(
                      'Create\nStory',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: topHeight - (addButtonSize / 2),
                  left: (cardWidth - addButtonSize) / 2,
                  child: Container(
                    padding: EdgeInsets.zero,
                    width: addButtonSize,
                    height: addButtonSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.primaryColor,
                      border: Border.all(
                        color: theme.scaffoldBackgroundColor,
                        width: borderWidth,
                      ),
                    ),
                    child:
                        isUploading
                            ? const CustomLoadingIndicator(
                              radius: 6,
                              color: AppColors.white,
                            )
                            : const Icon(
                              Icons.add,
                              color: AppColors.white,
                              size: 18,
                            ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
