import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/features/home/cubit/home_cubit.dart';
import 'package:social_media_app/features/home/models/story_model.dart';
import 'package:social_media_app/features/home/widgets/story_image_picker_sheet.dart';
import '../../../core/themes/app_colors.dart';

class StoryItemWidget extends StatelessWidget {
  final StoryModel? story;
  const StoryItemWidget({super.key, this.story});
  void _showAddStoryOptions(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: AppColors.white,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => StoryImagePickerSheet(
            onSelected: (source, type) {
              Navigator.pop(context);
              if (type == StoryType.text) {
                Navigator.of(context, rootNavigator: true).pushNamed(
                  AppRoutes.createTextStoryViewRoute,
                  arguments: context.read<HomeCubit>(),
                );
              } else {
                context.read<HomeCubit>().pickAndAddStory(source: source!);
              }
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (story == null) {
          _showAddStoryOptions(context);
          // Navigate to share story page
        } else {
          // Navigate to view story page
          Navigator.of(
            context,
            rootNavigator: true,
          ).pushNamed(AppRoutes.storyDisplayViewRoute, arguments: story);
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
                  story == null
                      ? AppColors.bgColor2
                      : (story!.imageUrl == null &&
                          story!.backgroundColor != null)
                      ? Color(int.parse(story!.backgroundColor!, radix: 16))
                      : AppColors.transparent,
              backgroundImage:
                  story?.imageUrl == null
                      ? null
                      : NetworkImage(story!.imageUrl!),

              child:
                  story == null
                      ? BlocBuilder<HomeCubit, HomeState>(
                        builder: (context, state) {
                          if (state is AddStoryLoading) {
                            return const Center(
                              child: CupertinoActivityIndicator(
                                radius: 10,
                                color: AppColors.black12,
                              ),
                            );
                          }
                          return const Icon(
                            Icons.add_outlined,
                            size: 22,
                            color: AppColors.white,
                          );
                        },
                      )
                      : (story!.imageUrl == null && story!.contentText != null)
                      ? Text(
                        story!.authorName[0].toUpperCase(),
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          color: AppColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
                story!.authorName.split(' ').first,

                // story!.authorId,
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
