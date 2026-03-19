import 'dart:io';
import 'package:flutter/material.dart';
import 'package:social_media_app/core/widgets/custom_user_profile_image_section.dart';
import '../../auth/data/models/user_data.dart';

class EditProfileImagesSection extends StatelessWidget {
  final File? selectedProfileImage;
  final File? selectedBackgroundImage;
  final UserData? userData;
  final VoidCallback onEditProfile;
  final VoidCallback onEditBackground;
  const EditProfileImagesSection({
    super.key,
    this.selectedProfileImage,
    this.selectedBackgroundImage,
    this.userData,
    required this.onEditProfile,
    required this.onEditBackground,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return CustomUserProfileImagesSection(
      isEditMode: true,
      totalHeight: size.height * 0.26,
      backgroundHeight: size.height * 0.22,
      avatarSize: 70,
      avatarAlignment: Alignment.bottomRight * 0.85,
      backgroundUrl: userData?.backgroundImageUrl,
      avatarUrl: userData?.imageUrl,
      selectedBackgroundFile: selectedBackgroundImage,
      selectedAvatarFile: selectedProfileImage,
      onEditBackground: onEditBackground,
      onEditAvatar: onEditProfile,
      heroTag: 'edit-profile-avatar',
    );
  }
}
