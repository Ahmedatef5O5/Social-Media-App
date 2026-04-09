import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/core/widgets/custom_user_profile_image_section.dart';
import 'package:social_media_app/features/auth/data/models/user_data.dart';
import 'package:social_media_app/features/profile/cubits/profile_cubit/profile_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/custom_elevated_button.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.size, required this.user});
  final Size size;
  final UserData user;
  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser!.id;
    final isMe = user.id == currentUserId;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            CustomUserProfileImagesSection(
              avatarAlignment: const Alignment(-0.82, 1.15),
              totalHeight: size.height * 0.38,
              backgroundHeight: size.height * 0.34,
              avatarSize: 115,
              backgroundUrl:
                  user.backgroundImageUrl ?? AppImages.defaultBackgroundImg,
              avatarUrl: user.imageUrl ?? AppImages.defaultUserImg,
              isProfileHeader: true,
              heroTag: 'edit-profile-avatar',
            ),
            if (!isMe)
              Align(
                alignment: Alignment.topLeft,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(context).pop(),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const Gap(22),
        Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (user.userName != null && user.userName!.isNotEmpty) ...[
                const Gap(4),
                Text(
                  "@${user.userName?.toLowerCase().replaceAll(' ', '_')}",

                  style: TextStyle(color: AppColors.grey, fontSize: 14),
                ),
              ],
              if (isMe && user.title != null && user.title!.isNotEmpty) ...[
                const Gap(4),
                Text(
                  user.title.toString(),
                  style: const TextStyle(fontSize: 16),
                ),
              ],
              if (isMe && user.bio != null && user.bio!.isNotEmpty) ...[
                const Gap(4),
                Text(user.bio.toString(), style: const TextStyle(fontSize: 16)),
              ],
            ],
          ),
        ),
        Gap(16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: CustomElevatedButton(
                  maximumSize: Size(260, 50),
                  minimumSize: Size(260, 50),
                  txtBtn: isMe ? 'EDIT PROFILE' : 'Follow',
                  txtBtnStyle: Theme.of(
                    context,
                  ).textTheme.titleMedium!.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  side: BorderSide(color: AppColors.grey3, width: 1.6),
                  elevation: 0,
                  bgColor: Theme.of(context).colorScheme.surface,

                  onPressed: () async {
                    if (isMe) {
                      final profileCubit = context.read<ProfileCubit>();
                      await Navigator.of(
                        context,
                        rootNavigator: true,
                      ).pushNamed(
                        AppRoutes.editProfileViewRoute,
                        arguments: user,
                      );
                      if (context.mounted) {
                        profileCubit.getProfileData(user.id);
                      }
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
