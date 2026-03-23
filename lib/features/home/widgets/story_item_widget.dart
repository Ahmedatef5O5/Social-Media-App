import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/features/home/cubit/home_cubit.dart';
import 'package:social_media_app/features/home/models/story_model.dart';
import 'package:social_media_app/features/home/widgets/story_image_picker_sheet.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/custom_loading_indicator.dart';

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
                final homeCubit = context.read<HomeCubit>();
                homeCubit.pickAndAddStory(source: source!);
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
        } else {
          final homeCubit = context.read<HomeCubit>();
          final allStories =
              homeCubit.cachedStories.isNotEmpty
                  ? homeCubit.cachedStories
                  : [story!];

          final index = allStories.indexWhere((s) => s.id == story!.id);

          print('allStories count: ${allStories.length}');
          print('current story index: $index');

          Navigator.of(context, rootNavigator: true).pushNamed(
            AppRoutes.storyDisplayViewRoute,
            arguments: {
              'stories': allStories,
              'initialIndex': index,
              'homeCubit': homeCubit,
            },
          );
        }
      },

      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.bgColor2,
              border:
                  story == null
                      ? null
                      : Border.all(
                        color: AppColors.primaryColor.withValues(alpha: 0.5),
                        width: 2,
                      ),
            ),
            child: CircleAvatar(
              radius: 8,
              backgroundColor:
                  story == null
                      ? AppColors.primaryColor.withValues(alpha: 0.2)
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
                            return const CustomLoadingIndicator();
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
