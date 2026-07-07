import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/constants/app_images.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/themes/background_theme_widget.dart';
import '../widgets/custom_post_type.dart';

class PostThemesView extends StatelessWidget {
  const PostThemesView({super.key});

  @override
  Widget build(BuildContext context) {
    return BackgroundThemeWidget(
      bottom: false,
      child: Scaffold(
        backgroundColor: AppColors.transparent,
        appBar: AppBar(
          backgroundColor: AppColors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close, size: 24),
          ),
          title: Text(
            'Create a Post',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.w400,
              fontSize: 18,
            ),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CustomPostType(
                        bgColor: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.9),
                        border: Border.all(
                          width: 1.4,
                          color: AppColors.black38,
                        ),
                        child: Image.asset(AppImages.textStoryIcon),
                      ),
                      CustomPostType(
                        bgColor: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.6),
                        border: Border.all(
                          width: 1.4,
                          color: AppColors.black38,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt_outlined,
                              size: 32,
                              color: AppColors.white,
                            ),
                            Gap(5),
                            Text(
                              'Camera',
                              style: Theme.of(
                                context,
                              ).textTheme.titleSmall!.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CustomPostType(
                        bgColor: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.18),
                        child: Image.asset(
                          AppImages.musicIcon,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(4),
                Divider(indent: 35, endIndent: 35),
                const Gap(8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 12,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 0,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.6,
                    ),
                    itemBuilder:
                        (context, index) => CustomPostType(
                          child: Image.asset(
                            AppImages.postThemes[index],
                            fit: BoxFit.contain,
                          ),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
