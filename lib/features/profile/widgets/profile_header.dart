import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/core/widgets/custom_user_profile_image_section.dart';
import 'package:social_media_app/features/auth/data/models/user_data.dart';
import 'package:social_media_app/features/profile/cubits/profile_cubit/profile_cubit.dart';
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
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CustomUserProfileImagesSection(
          totalHeight: size.height * 0.36,
          backgroundHeight: size.height * 0.3,
          avatarSize: 112,
          backgroundUrl:
              user.backgroundImageUrl ?? AppImages.defaultBackgroundImg,
          avatarUrl: user.imageUrl ?? AppImages.defaultUserImg,
          isProfileHeader: true,
          heroTag: 'edit-profile-avatar',
        ),
        Gap(16),
        Text(
          user.name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        if (user.userName != null && user.userName!.isNotEmpty) ...[
          const Gap(4),
          Text(
            "@${user.userName?.toLowerCase().replaceAll(' ', '_')}",

            style: TextStyle(color: AppColors.grey, fontSize: 14),
          ),
        ],
        if (user.title != null && user.title!.isNotEmpty) ...[
          const Gap(4),
          Text(user.title.toString(), style: const TextStyle(fontSize: 16)),
        ],
        if (user.bio != null && user.bio!.isNotEmpty) ...[
          const Gap(4),
          Text(user.bio.toString(), style: const TextStyle(fontSize: 16)),
        ],
        Gap(16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: CustomElevatedButton(
                  maximumSize: Size(260, 50),
                  minimumSize: Size(260, 50),
                  txtBtn: 'EDIT PROFILE',
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  side: BorderSide(color: AppColors.grey3, width: 1.6),
                  elevation: 0,
                  bgColor: AppColors.white,
                  txtColor: AppColors.black54,
                  onPressed: () async {
                    final profileCubit = context.read<ProfileCubit>();
                    await Navigator.of(context, rootNavigator: true).pushNamed(
                      AppRoutes.editProfileViewRoute,
                      arguments: user,
                    );

                    if (context.mounted) {
                      profileCubit.getProfileData(user.id);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
