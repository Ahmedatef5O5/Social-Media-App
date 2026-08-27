import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/core/design/theme/theme_extensions.dart';
import 'package:social_media_app/core/design/tokens/dimensions.dart';

enum AppAvatarSize { small, medium, large, xl, hero }

class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? fallbackText;
  final AppAvatarSize size;
  final bool isOnline;
  final bool hasStory;
  final bool isStorySeen;
  final VoidCallback? onTap;

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.fallbackText,
    this.size = AppAvatarSize.medium,
    this.isOnline = false,
    this.hasStory = false,
    this.isStorySeen = false,
    this.onTap,
  });

  double _getDimension() {
    switch (size) {
      case AppAvatarSize.small:
        return AppDimensions.avatarSmall; // 32
      case AppAvatarSize.medium:
        return AppDimensions.avatarMedium; // 40
      case AppAvatarSize.large:
        return AppDimensions.avatarLarge; // 48
      case AppAvatarSize.xl:
        return AppDimensions.avatarXl; // 72
      case AppAvatarSize.hero:
        return AppDimensions.avatarHero; // 96
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final dimension = _getDimension();

    Widget avatarImage = Container(
      width: dimension,
      height: dimension,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: palette.surfaceVariant,
        border: Border.all(
          color: palette.outline,
          width: AppDimensions.borderWidthDefault,
        ),
      ),
      child: ClipOval(
        child:
            (imageUrl != null && imageUrl!.isNotEmpty)
                ? CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) =>
                          Container(color: palette.surfaceVariant),
                  errorWidget: (context, url, error) => _buildFallback(context),
                )
                : _buildFallback(context),
      ),
    );

    // Add Story Gradient Ring if applicable
    if (hasStory) {
      final ringGradient =
          isStorySeen
              ? LinearGradient(
                colors: [palette.outline, palette.outlineVariant],
              )
              : LinearGradient(
                colors: [
                  palette.primary,
                  const Color(0xFFF43F5E),
                  const Color(0xFFFB923C),
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              );

      avatarImage = Container(
        padding: const EdgeInsets.all(AppDimensions.storyRingGap),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: ringGradient,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.storyRingGap),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: palette.surface,
          ),
          child: avatarImage,
        ),
      );
    }

    // Add Online Indicator Dot
    Widget content = avatarImage;
    if (isOnline) {
      content = Stack(
        clipBehavior: Clip.none,
        children: [
          avatarImage,
          Positioned(
            bottom: 1,
            right: 1,
            child: Container(
              width: AppDimensions.onlineDotSize,
              height: AppDimensions.onlineDotSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.success,
                border: Border.all(color: palette.surface, width: 2.0),
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: content);
    }
    return content;
  }

  Widget _buildFallback(BuildContext context) {
    final palette = context.palette;
    final text =
        (fallbackText != null && fallbackText!.isNotEmpty)
            ? fallbackText!.substring(0, 1).toUpperCase()
            : '?';

    return Center(
      child: Text(
        text,
        style: context.typography.titleMedium?.copyWith(
          color: palette.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
