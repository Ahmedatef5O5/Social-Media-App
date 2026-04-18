import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/features/home/cubits/home_cubit/home_cubit.dart';
import 'package:social_media_app/features/stories/model/story_model.dart';
import 'package:social_media_app/features/stories/widgets/story_image_picker_sheet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/custom_loading_indicator.dart';

class StoryItemWidget extends StatefulWidget {
  final StoryModel? story;
  final List<StoryModel>? userStroies;
  final List<List<StoryModel>>? allUserGroups;

  const StoryItemWidget({
    super.key,
    this.story,
    this.userStroies,
    this.allUserGroups,
  });

  @override
  State<StoryItemWidget> createState() => _StoryItemWidgetState();
}

class _StoryItemWidgetState extends State<StoryItemWidget> {
  bool _navigationHandled = false;

  void _showAddStoryOptions(BuildContext context) {
    final homeCubit = context.read<HomeCubit>();
    showModalBottomSheet(
      useRootNavigator: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor.withValues(),
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => BlocProvider.value(
            value: homeCubit,
            child: StoryImagePickerSheet(
              onSelected: (source, type) {
                Navigator.pop(context);
                _navigationHandled = false;
                switch (type) {
                  case StoryPickType.text:
                    Navigator.of(context, rootNavigator: true).pushNamed(
                      AppRoutes.createTextStoryViewRoute,
                      arguments: homeCubit,
                    );
                    break;
                  case StoryPickType.image:
                    homeCubit.pickAndAddStory(source: source!);
                    break;
                  case StoryPickType.video:
                    homeCubit.pickAndPreviewVideoStory(source: source!);
                    break;
                }
              },
            ),
          ),
    );
  }

  void _navigateToPreview({
    required BuildContext context,
    required File file,
    required bool isVideo,
    Duration? videoDuration,
  }) {
    if (_navigationHandled) return;
    _navigationHandled = true;

    Navigator.of(context, rootNavigator: true)
        .pushNamed(
          AppRoutes.addStoryPreviewViewRoute,
          arguments: {
            'file': file,
            'isVideo': isVideo,
            if (videoDuration != null) 'videoDuration': videoDuration,
            'homeCubit': context.read<HomeCubit>(),
          },
        )
        .whenComplete(() => _navigationHandled = false);
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return BlocListener<HomeCubit, HomeState>(
      listenWhen:
          (_, current) =>
              widget.story == null &&
              (current is StoryImagePicked || current is StoryVideoPicked),
      listener: (context, state) {
        if (state is StoryImagePicked) {
          _navigateToPreview(
            context: context,
            file: state.file,
            isVideo: false,
          );
        } else if (state is StoryVideoPicked) {
          _navigateToPreview(
            context: context,
            file: state.file,
            isVideo: true,
            videoDuration: state.videoDuration,
          );
        }
      },
      child: InkWell(
        onTap: () {
          if (widget.story == null) {
            _showAddStoryOptions(context);
          } else {
            final homeCubit = context.read<HomeCubit>();
            final stories = widget.userStroies ?? [widget.story!];
            final groups = widget.allUserGroups ?? [stories];
            final groupIndex = groups.indexWhere(
              (g) => g.first.authorId == widget.story!.authorId,
            );
            Navigator.of(context, rootNavigator: true).pushNamed(
              AppRoutes.storyDisplayViewRoute,
              arguments: {
                'homeCubit': homeCubit,
                'allUserGroups': groups,
                'initialGroupIndex': groupIndex,
              },
            );
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.8),
                    border:
                        widget.story == null
                            ? null
                            : Border.all(
                              color: Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.5),
                              width: 2,
                            ),
                  ),
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor:
                        widget.story == null
                            ? Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.2)
                            : widget.story!.storyType == StoryType.video
                            ? Colors.black
                            : (widget.story!.imageUrl == null &&
                                widget.story!.videoUrl == null &&
                                widget.story!.backgroundColor != null)
                            ? Color(
                              int.parse(
                                widget.story!.backgroundColor!,
                                radix: 16,
                              ),
                            )
                            : AppColors.transparent,
                    backgroundImage:
                        widget.story?.imageUrl == null
                            ? null
                            : NetworkImage(widget.story!.imageUrl!),
                    child:
                        widget.story == null
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
                            : widget.story!.storyType == StoryType.video
                            ? Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white.withValues(alpha: 0.85),
                              size: 22,
                            )
                            : (widget.story!.imageUrl == null &&
                                widget.story!.videoUrl == null &&
                                widget.story!.contentText != null)
                            ? Text(
                              widget.story!.authorName[0].toUpperCase(),
                              style: Theme.of(
                                context,
                              ).textTheme.titleSmall!.copyWith(
                                color: AppColors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                            : null,
                  ),
                ),
              ],
            ),
            const Gap(6),
            widget.story == null
                ? Text(
                  'Share Story',
                  textAlign: TextAlign.start,
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w300,
                  ),
                )
                : Text(
                  widget.story!.authorId == currentUserId
                      ? 'You'
                      : widget.story!.authorName.split(' ').first,
                  textAlign: TextAlign.start,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w400),
                ),
          ],
        ),
      ),
    );
  }
}
