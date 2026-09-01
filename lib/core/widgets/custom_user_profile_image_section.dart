import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/widgets/app_avatar.dart';
import '../presence/cubits/presence_cubit/presence_cubit.dart';
import '../presence/widgets/presence_avatar_widget.dart';

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
  final String? profileUserId;
  final bool? showBorder;

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
    this.profileUserId,
    this.showBorder,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double dynamicBackgroundHeight = screenWidth / aspectRatio;
    final double dynamicAvatarSize = screenWidth * avatarSizeFactor;
    final double calculatedTotalHeight =
        dynamicBackgroundHeight + (dynamicAvatarSize / 2);

    final bool isOnline =
        profileUserId != null &&
        context.select<PresenceCubit, bool>(
          (cubit) => cubit.isOnline(profileUserId!),
        );

    return SizedBox(
      height: totalHeight ?? calculatedTotalHeight,
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

          // ─── Avatar Section ───
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
                      if (selectedAvatarFile != null)
                        Container(
                          width: dynamicAvatarSize,
                          height: dynamicAvatarSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: FileImage(selectedAvatarFile!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      else
                        PresenceAvatarWidget(
                          userId: profileUserId ?? '',
                          avatarSize: dynamicAvatarSize,
                          showDot: profileUserId != null,
                          showBorder: showBorder ?? true,
                          child: AppAvatar(
                            imageUrl: avatarUrl,
                            size: dynamicAvatarSize,
                            borderColor:
                                (!isEditMode && !isOnline)
                                    ? Theme.of(context).primaryColor
                                    : Colors.transparent,
                            borderWidth:
                                (!isEditMode && !isOnline)
                                    ? (isProfileHeader ? 2.2 : 2.0)
                                    : 0.0,
                          ),
                        ),

                      if (isEditMode)
                        CircleAvatar(
                          radius: dynamicAvatarSize / 2,
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
      String safeUrl = backgroundUrl!;
      safeUrl = safeUrl.replaceAll(
        RegExp(r'\.heic$', caseSensitive: false),
        '.jpg',
      );
      return CachedNetworkImageProvider(safeUrl);
    }
    return const AssetImage(AppImages.defaultBackgroundImg);
  }
}

void _openFullScreenImage(BuildContext context, String url, String tag) {
  Navigator.of(context, rootNavigator: true).pushNamed(
    AppRoutes.fullScreenImageViewRoute,
    arguments: {'url': url, 'tag': tag, 'isAsset': !url.startsWith('http')},
  );
}
