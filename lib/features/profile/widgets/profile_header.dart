import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/features/auth/data/models/user_data.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/custom_elevated_button.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.size, required this.user});
  final Size size;
  final UserData user;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: size.height * 0.36,

          child: Stack(
            children: [
              Container(
                height: size.height * 0.3,
                width: size.width,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(
                      user.backgroundImageUrl ?? AppImages.defaultBackgroundImg,
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  height: 112,
                  width: 112,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.primaryColor,
                        width: 4,
                      ),
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: CachedNetworkImageProvider(
                          user.imageUrl ?? AppImages.defaultUserImg,
                        ),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Gap(16),
        Text(
          user.name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),

        const Gap(4),
        Text(
          "@${user.name.toLowerCase().replaceAll(' ', '_')}",
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        Gap(8),
        const Text('Mobile Developer', style: TextStyle(fontSize: 16)),
        Gap(16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Row(
            children: [
              Expanded(
                child: CustomElevatedButton(
                  maximumSize: Size(220, 90),
                  minimumSize: Size(220, 50),
                  txtBtn: 'EDIT PROFILE',

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  side: BorderSide(color: AppColors.grey3, width: 1.6),
                  elevation: 0,
                  bgColor: AppColors.white,
                  txtColor: AppColors.black54,
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pushNamed(
                      AppRoutes.editProfileViewRoute,
                      arguments: user,
                    );
                  },
                ),
              ),
              const Gap(12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.grey3, width: 1.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: InkWell(
                  onTap: () {},
                  child: Image.asset(
                    AppImages.settingsIcon,
                    width: 26,
                    height: 26,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
