import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/features/home/cubits/home_cubit/home_cubit.dart';
import '../cubit/stories_cubit/stories_cubit.dart';
import '../widgets/story_image_picker_sheet.dart';

class StoryCreationLauncher {
  const StoryCreationLauncher._();

  static void openPicker(BuildContext context, StoriesCubit storiesCubit) {
    showModalBottomSheet(
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor.withValues(),
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (sheetContext) => BlocProvider.value(
            value: storiesCubit,
            child: StoryImagePickerSheet(
              onSelected: (source, type) {
                Navigator.pop(sheetContext);
                switch (type) {
                  case StoryPickType.text:
                    Navigator.of(context, rootNavigator: true).pushNamed(
                      AppRoutes.createTextStoryViewRoute,
                      arguments: {
                        'storiesCubit': storiesCubit,
                        'currentUser':
                            context.read<HomeCubit>().currentUserData,
                      },
                    );
                    break;
                  case StoryPickType.image:
                    storiesCubit.pickAndAddStory(source: source!);
                    break;
                  case StoryPickType.video:
                    storiesCubit.pickAndPreviewVideoStory(source: source!);
                    break;
                }
              },
            ),
          ),
    );
  }

  static Future<void> navigateToPreview({
    required BuildContext context,
    required StoriesCubit storiesCubit,
    required File file,
    required bool isVideo,
    Duration? videoDuration,
  }) {
    return Navigator.of(context, rootNavigator: true).pushNamed(
      AppRoutes.addStoryPreviewViewRoute,
      arguments: {
        'file': file,
        'isVideo': isVideo,
        if (videoDuration != null) 'videoDuration': videoDuration,
        'storiesCubit': storiesCubit,
        'currentUser': context.read<HomeCubit>().currentUserData,
      },
    );
  }
}
