import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/themes/app_colors.dart';
import '../../auth/data/models/user_data.dart';

class EditProfileImagesSection extends StatelessWidget {
  //
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
    return SizedBox(
      height: size.height * 0.26,
      child: Stack(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: size.height * 0.22,
                width: size.width,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20),
                    bottom: Radius.circular(20),
                  ),
                  image: DecorationImage(
                    image:
                        selectedBackgroundImage != null
                            ? FileImage(selectedBackgroundImage!)
                                as ImageProvider
                            : CachedNetworkImageProvider(
                              userData?.backgroundImageUrl ??
                                  AppImages.defaultBackgroundImg,
                            ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              Container(
                height: size.height * 0.22,
                width: size.width,
                decoration: BoxDecoration(
                  color: AppColors.black26,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20),
                    bottom: Radius.circular(20),
                  ),
                ),
                child: InkWell(
                  onTap: onEditBackground,

                  child: Icon(Icons.edit, color: AppColors.white),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomRight * 0.85,
            child: SizedBox(
              height: 70,
              width: 70,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.primaryColor,
                        width: 3,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage:
                          selectedProfileImage != null
                              ? FileImage(selectedProfileImage!)
                                  as ImageProvider
                              : CachedNetworkImageProvider(
                                userData?.imageUrl ?? AppImages.defaultUserImg,
                              ),
                    ),
                  ),
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.black38,
                    child: InkWell(
                      onTap: onEditProfile,
                      child: Icon(Icons.edit, color: AppColors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
