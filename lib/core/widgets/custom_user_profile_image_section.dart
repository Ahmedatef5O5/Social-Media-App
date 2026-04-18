import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import '../../../core/constants/app_images.dart';

class CustomUserProfileImagesSection extends StatelessWidget {
  final double aspectRatio;
  final double avatarSizeFactor;
  final double? totalHeight;
  final double? backgroundHeight;
  final String? backgroundUrl;
  final String? avatarUrl;
  final File? selectedBackgroundFile;
  final File? selectedAvatarFile;
  final bool isEditMode, isProfileHeader;
  final VoidCallback? onEditBackground;
  final VoidCallback? onEditAvatar;
  final Alignment avatarAlignment;
  final String? heroTag;

  const CustomUserProfileImagesSection({
    super.key,
    this.aspectRatio = 1.8,
    this.avatarSizeFactor = 0.28,
    this.totalHeight,
    this.backgroundHeight,
    this.backgroundUrl,
    this.avatarUrl,
    this.selectedBackgroundFile,
    this.selectedAvatarFile,
    this.isEditMode = false,
    this.isProfileHeader = false,
    this.onEditBackground,
    this.onEditAvatar,
    this.avatarAlignment = Alignment.bottomCenter,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double dynamicBackgroundHeight = screenWidth / aspectRatio;
    final double dynamicAvatarSize = screenWidth * avatarSizeFactor;

    final double totalHeight =
        dynamicBackgroundHeight + (dynamicAvatarSize / 2);

    return SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap:
                isEditMode
                    ? onEditBackground
                    : () {
                      final String url =
                          backgroundUrl ?? AppImages.defaultBackgroundImg;
                      _openFullScreenImage(context, url, 'background-$url');
                    },
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: dynamicBackgroundHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius:
                        isEditMode
                            ? const BorderRadius.vertical(
                              bottom: Radius.circular(20),
                              top: Radius.circular(20),
                            )
                            : isProfileHeader
                            ? const BorderRadius.vertical(
                              bottom: Radius.circular(20),
                            )
                            : null,
                    image: DecorationImage(
                      image: _getBackgroundImage(),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (isEditMode)
                  Container(
                    height: dynamicBackgroundHeight,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).scaffoldBackgroundColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.edit,
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.9),
                      size: 28,
                    ),
                  ),
              ],
            ),
          ),

          Align(
            alignment: avatarAlignment,
            child: GestureDetector(
              onTap:
                  isEditMode
                      ? onEditAvatar
                      : () {
                        final String url =
                            avatarUrl ?? AppImages.defaultUserImg;
                        _openFullScreenImage(context, url, 'avatar-$url');
                      },
              child: Hero(
                tag: heroTag ?? 'default-avatar-tag-${avatarUrl ?? "none"}',
                child: SizedBox(
                  height: dynamicAvatarSize,
                  width: dynamicAvatarSize,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                              !isEditMode
                                  ? Border.all(
                                    color: Theme.of(context).primaryColor,
                                    width: isProfileHeader ? 2.2 : 2,
                                  )
                                  : null,
                          image: DecorationImage(
                            image: _getAvatarImage(),
                            fit: BoxFit.cover,
                            onError: (exception, stackTrace) {
                              debugPrint("Error loading image: $exception");
                            },
                          ),
                        ),
                      ),

                      if (isEditMode)
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Theme.of(
                            context,
                          ).scaffoldBackgroundColor.withValues(alpha: 0.25),
                          child: Icon(
                            Icons.edit,

                            color: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.9),
                            size: 26,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider _getBackgroundImage() {
    if (selectedBackgroundFile != null) {
      return FileImage(selectedBackgroundFile!);
    }
    if (backgroundUrl != null && backgroundUrl!.startsWith('http')) {
      return CachedNetworkImageProvider(backgroundUrl!);
    }

    return const AssetImage(AppImages.defaultBackgroundImg);
  }

  ImageProvider _getAvatarImage() {
    if (selectedAvatarFile != null) return FileImage(selectedAvatarFile!);
    if (avatarUrl != null && avatarUrl!.startsWith('http')) {
      return CachedNetworkImageProvider(avatarUrl!);
    }

    return const AssetImage(AppImages.defaultUserImg);
  }
}

void _openFullScreenImage(BuildContext context, String url, String tag) {
  Navigator.of(context, rootNavigator: true).pushNamed(
    AppRoutes.fullScreenImageViewRoute,
    arguments: {'url': url, 'tag': tag, 'isAsset': !url.startsWith('http')},
  );
}
