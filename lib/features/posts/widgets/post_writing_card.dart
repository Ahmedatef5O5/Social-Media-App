import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import 'package:social_media_app/core/widgets/main_user_avatar.dart';
import 'package:social_media_app/features/home/cubits/home_cubit/home_cubit.dart';
import '../../../core/constants/app_images.dart';

class PostWritingCard extends StatelessWidget {
  const PostWritingCard({super.key});

  @override
  Widget build(BuildContext context) {
    // to be Responsive
    final screenSize = MediaQuery.sizeOf(context);
    final isSmallScreen = screenSize.width < 360;

    navigatorToPost() => Navigator.of(context, rootNavigator: true).pushNamed(
      AppRoutes.createPostViewRoute,
      arguments: context.read<HomeCubit>(),
    );
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final homeCubit = context.read<HomeCubit>();
        final user = homeCubit.currentUserData;
        final displayImage = user?.imageUrl;
        return InkWell(
          onTap: navigatorToPost,
          child: Stack(
            children: [
              Image.asset(
                AppImages.backgroundShape,
                width: double.infinity,
                fit: BoxFit.fill,
                color: Theme.of(context).primaryColor,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 4,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Gap(4),
                    Row(
                      children: [
                        Hero(
                          tag: 'user-avatar-hero',
                          child: MainUserAvatar(
                            imageUrl: displayImage,
                            size: isSmallScreen ? 30 : 36,
                            showBorder: true,
                          ),
                        ),
                        Gap(12),
                        Expanded(
                          child: Text(
                            'What\'s on your head?',
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium!.copyWith(
                              color: Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w300,
                              fontSize: isSmallScreen ? 16 : 18,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Gap(screenSize.height * 0.038),

                    LayoutBuilder(
                      builder: (
                        BuildContext context,
                        BoxConstraints constraints,
                      ) {
                        return Container(
                          width: constraints.maxWidth * 0.85,
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: 1.8,
                              color: Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.12),
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  AppImages.imageIcon,
                                  width: 62,
                                  color: Theme.of(context).primaryColor,
                                ),
                                SizedBox(
                                  height: 16,
                                  child: VerticalDivider(
                                    color: AppColors.black26,
                                  ),
                                ),

                                Image.asset(
                                  AppImages.videosIcon,
                                  width: 62,
                                  color: Theme.of(context).primaryColor,
                                ),
                                SizedBox(
                                  height: 16,
                                  child: VerticalDivider(
                                    color: AppColors.black26,
                                  ),
                                ),

                                Image.asset(
                                  AppImages.attachIcon,
                                  width: 62,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
