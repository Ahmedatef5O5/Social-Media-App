import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/features/home/models/story_model.dart';
import '../../../core/themes/app_colors.dart';

class StoryItemWidget extends StatelessWidget {
  final StoryModel? story;
  const StoryItemWidget({super.key, this.story});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (story == null) {
          // Navigate to share story page
        } else {
          // Navigate to view story page
        }
      },
      child: Column(
        children: [
          Container(
            height: 50,
            width: 50,
            // margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.bgColor2,
              border: Border.all(color: AppColors.bgColor2, width: 2),
            ),
            child: CircleAvatar(
              radius: 8,

              backgroundColor:
                  story == null ? AppColors.bgColor2 : AppColors.transparent,
              backgroundImage:
                  story == null ? null : NetworkImage(story!.imageUrl),

              child:
                  story == null
                      ? const Icon(
                        Icons.add_outlined,
                        size: 22,
                        color: AppColors.white,
                      )
                      : null,
            ),
          ),
          Gap(6),
          story == null
              ? Text(
                'Share Story',
                textAlign: TextAlign.start,
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w300,
                  color: AppColors.grey6,
                ),
              )
              : Text(
                story!.authorId,
                // 'User',
                textAlign: TextAlign.start,
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  fontWeight: FontWeight.w400,
                  color: AppColors.grey9,
                ),
              ),
        ],
      ),
    );
  }
}
