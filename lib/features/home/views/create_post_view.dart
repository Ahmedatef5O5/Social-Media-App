import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import 'package:social_media_app/core/themes/background_theme_widget.dart';

class CreatePostView extends StatelessWidget {
  const CreatePostView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundThemeWidget(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Gap(12),
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, size: 24, color: AppColors.black54),
                  ),
                  Gap(4),
                  Text(
                    'Create a Post',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w400,
                      color: AppColors.black54,
                      fontSize: 16,
                    ),
                  ),
                  Spacer(),
                  Text(
                    'Post',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.black54,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
              Gap(12),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  CircleAvatar(radius: 18, child: Icon(Icons.person)),
                  Gap(12),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(width: 1, color: AppColors.black38),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Public',
                            style: Theme.of(
                              context,
                            ).textTheme.titleSmall!.copyWith(
                              color: AppColors.black87,
                              fontSize: 17,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            size: 26,
                            color: AppColors.black38,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Gap(12),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'What\'s on your head?',
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    color: AppColors.black54,
                    fontSize: 19,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
