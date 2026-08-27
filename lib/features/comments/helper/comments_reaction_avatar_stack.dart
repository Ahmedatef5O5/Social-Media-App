import 'package:flutter/material.dart';
import 'package:social_media_app/core/widgets/cached_cloudinary_image.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import 'package:social_media_app/features/posts/model/post_reaction_model.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/design/tokens/typography.dart';

class CommentsReactionAvatarStack extends StatelessWidget {
  final List<String> imageUrls;
  final int totalReactions;
  final List<PostReactionModel> reactions;

  const CommentsReactionAvatarStack({
    super.key,
    required this.imageUrls,
    required this.totalReactions,
    required this.reactions,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty && totalReactions == 0) {
      return const SizedBox.shrink();
    }

    const int maxVisible = 6;
    final int visibleCount =
        imageUrls.length > maxVisible ? maxVisible : imageUrls.length;
    final int remainingCount =
        totalReactions > visibleCount ? totalReactions - visibleCount : 0;
    final bool showRemaining = remainingCount > 0;

    const double avatarSize = 28;
    const double overlapOffset = 20;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    final borderColor = theme.scaffoldBackgroundColor;
    final remainingBgColor =
        isDark ? colorScheme.surfaceContainerHighest : Colors.grey[300];
    final remainingTextColor =
        isDark ? colorScheme.onSurface : colorScheme.onSurface;

    final topEmojis = reactions.map((r) => r.emoji).toList();
    final int totalCircles = visibleCount + (showRemaining ? 1 : 0);
    final double stackWidth = (totalCircles - 1) * overlapOffset + avatarSize;

    return SizedBox(
      height: avatarSize,
      width: stackWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (showRemaining)
            Positioned(
              left: visibleCount * overlapOffset,
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: remainingBgColor,
                  border: Border.all(color: borderColor, width: 2.0),
                ),
                child: Center(
                  child: Text(
                    '+$remainingCount',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: remainingTextColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
            ),
          for (int i = visibleCount - 1; i >= 0; i--)
            Positioned(
              left: i * overlapOffset,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: remainingBgColor,
                      border: Border.all(color: borderColor, width: 2.0),
                    ),
                    child: ClipOval(child: _buildImage(imageUrls[i])),
                  ),
                  if (topEmojis.isNotEmpty)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: _buildEmojiBadge(
                        topEmojis[i % topEmojis.length],
                        borderColor,
                        isDark,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage(String url) {
    if (url.isEmpty || !url.startsWith('http') || url == 'asset:default') {
      return Image.asset(AppImages.defaultUserImg, fit: BoxFit.cover);
    }

    return CachedCloudinaryImage(
      secureUrl: url,
      fit: BoxFit.cover,
      isAvatar: true,
      errorWidget:
          (context, error) =>
              Image.asset(AppImages.defaultUserImg, fit: BoxFit.cover),
      placeholder: (context) => const CustomLoadingIndicator(),
    );
  }

  Widget _buildEmojiBadge(String emoji, Color borderColor, bool isDark) {
    final String displayEmoji = emoji.toLowerCase() == 'like' ? '👍' : emoji;

    return Container(
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        displayEmoji,
        style: TextStyle(
          inherit: false,
          fontFamilyFallback: AppTypography.emojiFontFallback,
          fontSize: 8,
          height: 1.1,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }
}
