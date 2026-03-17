import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import 'package:social_media_app/core/widgets/main_user_avatar.dart';
import 'package:social_media_app/features/home/cubit/home_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_images.dart';

class PostWritingCard extends StatelessWidget {
  const PostWritingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final homeCubit = context.read<HomeCubit>();
    final user = homeCubit.currentUserData;
    final authUser = Supabase.instance.client.auth.currentUser;

    //
    final displayImage =
        user?.imageUrl ?? authUser?.userMetadata?['avatar_url'];

    navigatorToPost() => Navigator.of(context, rootNavigator: true).pushNamed(
      AppRoutes.createPostViewRoute,
      arguments: context.read<HomeCubit>(),
    );
    return Stack(
      children: [
        Image.asset(AppImages.backgroundShape, width: 370),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Gap(4),
              Row(
                children: [
                  MainUserAvatar(
                    imageUrl: displayImage,
                    size: 36,
                    showBorder: true,
                  ),
                  Gap(12),
                  InkWell(
                    onTap: navigatorToPost,
                    child: Text(
                      'What\'s on your head?',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: AppColors.black45,
                        fontWeight: FontWeight.w300,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              Gap(38),
              SizedBox(
                width: 250,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(width: 1.8, color: AppColors.bgColor),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: navigatorToPost,
                          child: Image.asset(AppImages.imageIcon, width: 62),
                        ),
                        SizedBox(
                          height: 16,
                          child: VerticalDivider(color: AppColors.black26),
                        ),

                        InkWell(
                          onTap: navigatorToPost,
                          child: Image.asset(AppImages.videosIcon, width: 62),
                        ),
                        SizedBox(
                          height: 16,
                          child: VerticalDivider(color: AppColors.black26),
                        ),

                        InkWell(
                          onTap: navigatorToPost,
                          child: Image.asset(AppImages.attachIcon, width: 62),
                        ),
                      ],
                    ),
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
