import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/themes/app_colors.dart';

class CustomUserProfileImagesSection extends StatelessWidget {
  final double totalHeight;
  final double backgroundHeight;
  final double avatarSize;
  final String? backgroundUrl;
  final String? avatarUrl;
  final File? selectedBackgroundFile;
  final File? selectedAvatarFile;
  final bool isEditMode, isProfileHeader;
  final VoidCallback? onEditBackground;
  final VoidCallback? onEditAvatar;
  final Alignment avatarAlignment;

  const CustomUserProfileImagesSection({
    super.key,
    required this.totalHeight,
    required this.backgroundHeight,
    this.avatarSize = 80,
    this.backgroundUrl,
    this.avatarUrl,
    this.selectedBackgroundFile,
    this.selectedAvatarFile,
    this.isEditMode = false,
    this.isProfileHeader = false,
    this.onEditBackground,
    this.onEditAvatar,
    this.avatarAlignment = Alignment.bottomCenter,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: totalHeight,
      child: Stack(
        children: [
          GestureDetector(
            onTap: isEditMode ? onEditBackground : null,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: backgroundHeight,
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
                    height: backgroundHeight,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.edit, color: Colors.white),
                  ),
              ],
            ),
          ),

          Align(
            alignment: avatarAlignment,
            child: GestureDetector(
              onTap: isEditMode ? onEditAvatar : null,
              child: SizedBox(
                height: avatarSize,
                width: avatarSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            !isEditMode
                                ? Border.all(
                                  color: AppColors.primaryColor,
                                  width: isProfileHeader ? 4 : 2,
                                )
                                : null,
                        image: DecorationImage(
                          image: _getAvatarImage(),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    if (isEditMode)
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.black38,
                        child: Icon(Icons.edit, color: AppColors.white),
                      ),
                  ],
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
    return CachedNetworkImageProvider(
      backgroundUrl ?? AppImages.defaultBackgroundImg,
      errorListener:
          (p0) => const CustomLoadingIndicator(color: AppColors.black12),
    );
  }

  ImageProvider _getAvatarImage() {
    if (selectedAvatarFile != null) return FileImage(selectedAvatarFile!);
    return CachedNetworkImageProvider(
      avatarUrl ?? AppImages.defaultUserImg,
      errorListener: (p0) => const CustomLoadingIndicator(),
    );
  }
}
