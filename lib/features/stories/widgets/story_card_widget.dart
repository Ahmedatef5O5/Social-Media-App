import 'package:flutter/material.dart';
import 'package:social_media_app/core/design/tokens/typography.dart';
import 'package:social_media_app/core/helpers/emoji_helper.dart';
import 'package:social_media_app/core/presence/widgets/presence_avatar_widget.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import 'package:social_media_app/core/widgets/cached_cloudinary_image.dart';
import '../../../core/cache/utils/cloudinary_url_extensions.dart';
import '../../../core/helpers/chat_helper.dart';
import '../../../core/widgets/app_avatar.dart';
import '../model/story_model.dart';

class StoryCardWidget extends StatelessWidget {
  static const double cardWidth = 110;
  static const double cardHeight = 170;

  final StoryModel story;
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onAddTap;

  const StoryCardWidget({
    super.key,
    required this.story,
    required this.label,
    required this.onTap,
    this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: cardWidth,
        height: cardHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              Positioned.fill(child: _buildCover(theme)),

              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.55, 1.0],
                      colors: [
                        Colors.black.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: 0.65),
                      ],
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 8,
                left: 8,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    PresenceAvatarWidget(
                      userId: story.authorId,
                      avatarSize: 34,
                      showDot: true,
                      showBorder: false,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.primaryColor,
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child:
                              story.authorImageUrl == null
                                  ? AppAvatar(
                                    imageUrl: story.authorImageUrl,
                                    size: 34,
                                  )
                                  : CachedCloudinaryImage(
                                    secureUrl: story.authorImageUrl!,
                                    fit: BoxFit.cover,
                                    width: 34,
                                    height: 34,
                                    isAvatar: true,
                                  ),
                        ),
                      ),
                    ),
                    if (onAddTap != null)
                      Positioned(
                        right: -0.9,
                        bottom: -0.9,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onAddTap,
                          child: Container(
                            width: 11,
                            height: 11,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.primaryColor,
                              border: Border.all(
                                color: AppColors.white,
                                width: .8,
                              ),
                            ),
                            child: Center(
                              child: const Icon(
                                Icons.add,
                                color: AppColors.white,
                                size: 9,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Text(
                  EmojiHelper.normalize(label),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                    fontFamily: null,
                    fontFamilyFallback: AppTypography.fontFallback,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCover(ThemeData theme) {
    if (story.imageUrl != null) {
      return CachedCloudinaryImage(
        secureUrl: story.imageUrl!,
        fit: BoxFit.cover,
        width: cardWidth,
        height: cardHeight,
        placeholder: (_) => Container(color: theme.dividerColor),
        errorWidget: (_, __) => Container(color: Colors.black87),
      );
    }
    if (story.storyType == StoryType.video) {
      final thumbUrl = story.videoUrl?.cloudinaryVideoThumbnailUrl;

      if (thumbUrl != null) {
        return CachedCloudinaryImage(
          secureUrl: thumbUrl,
          fit: BoxFit.cover,
          width: cardWidth,
          height: cardHeight,
          placeholder: (_) => Container(color: theme.dividerColor),
          errorWidget: (_, __) => Container(color: Colors.black87),
        );
      }
      return Container(color: Colors.black87);
    }
    final bg =
        story.backgroundColor != null
            ? Color(int.parse(story.backgroundColor!, radix: 16))
            : theme.primaryColor;
    return Container(
      color: bg,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        EmojiHelper.normalize(story.contentText ?? ''),
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        textDirection: ChatHelper.getTextDirection(story.contentText ?? 'EN'),
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          fontFamily: null,
          fontFamilyFallback: AppTypography.fontFallback,
        ),
      ),
    );
  }
}
