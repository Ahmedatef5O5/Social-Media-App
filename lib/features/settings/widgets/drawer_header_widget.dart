import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/widgets/custom_user_profile_image_section.dart';
import '../../auth/data/models/user_data.dart';

class DrawerHeaderWidget extends StatelessWidget {
  final UserData user;
  const DrawerHeaderWidget({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Stack(
            children: [
              CustomUserProfileImagesSection(
                totalHeight: size.height * 0.26,
                backgroundHeight: size.height * 0.22,
                avatarSize: 80,
                backgroundUrl:
                    user.backgroundImageUrl ?? AppImages.defaultBackgroundImg,
                avatarUrl: user.imageUrl ?? AppImages.defaultUserImg,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 12,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 26,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),

          const Gap(12),
          Text(
            user.name,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          if (user.userName != null) ...[
            const Gap(2),
            Text(
              "@${user.userName?.toLowerCase().replaceAll(' ', '_')}",

              style: TextStyle(color: AppColors.grey, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}
