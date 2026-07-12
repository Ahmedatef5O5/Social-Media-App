import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/features/home/cubits/home_cubit/home_cubit.dart';
import 'package:social_media_app/features/stories/model/story_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../cubit/stories_cubit/stories_cubit.dart';
import '../helpers/story_creation_launcher.dart';

class StoryItemWidget extends StatefulWidget {
  final StoryModel? story;
  final bool isOwnTile;
  final List<StoryModel>? userStroies;
  final List<List<StoryModel>>? allUserGroups;

  const StoryItemWidget({
    super.key,
    this.story,
    this.isOwnTile = false,
    this.userStroies,
    this.allUserGroups,
  });

  @override
  State<StoryItemWidget> createState() => _StoryItemWidgetState();
}

class _StoryItemWidgetState extends State<StoryItemWidget> {
  bool _navigationHandled = false;

  bool get _hasOwnStories =>
      widget.isOwnTile && (widget.userStroies?.isNotEmpty ?? false);

  void _showAddStoryOptions(BuildContext context) {
    StoryCreationLauncher.openPicker(context, context.read<StoriesCubit>());
  }

  void _navigateToPreview({
    required BuildContext context,
    required File file,
    required bool isVideo,
    Duration? videoDuration,
  }) {
    if (_navigationHandled) return;
    _navigationHandled = true;

    StoryCreationLauncher.navigateToPreview(
      context: context,
      storiesCubit: context.read<StoriesCubit>(),
      file: file,
      isVideo: isVideo,
      videoDuration: videoDuration,
    ).whenComplete(() => _navigationHandled = false);
  }

  void _openMyStories(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pushNamed(
      AppRoutes.myStoriesListViewRoute,
      arguments: {
        'storiesCubit': context.read<StoriesCubit>(),
        'myStories': widget.userStroies,
      },
    );
  }

  void _openOtherUserStory(BuildContext context) {
    final storiesCubit = context.read<StoriesCubit>();
    final stories = widget.userStroies ?? [widget.story!];
    final groups = widget.allUserGroups ?? [stories];
    final groupIndex = groups.indexWhere(
      (g) => g.first.authorId == widget.story!.authorId,
    );
    Navigator.of(context, rootNavigator: true).pushNamed(
      AppRoutes.storyDisplayViewRoute,
      arguments: {
        'storiesCubit': storiesCubit,
        'allUserGroups': groups,
        'initialGroupIndex': groupIndex,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return BlocListener<StoriesCubit, StoriesState>(
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
      child: GestureDetector(
        onTap: () {
          if (widget.isOwnTile) {
            _hasOwnStories
                ? _openMyStories(context)
                : _showAddStoryOptions(context);
          } else if (widget.story == null) {
            _showAddStoryOptions(context);
          } else {
            _openOtherUserStory(context);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                _buildAvatarCircle(context, currentUserId),
                if (_hasOwnStories)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _showAddStoryOptions(context),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).primaryColor,
                          border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const Gap(6),
            _buildLabel(context, currentUserId),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarCircle(BuildContext context, String? currentUserId) {
    if (_hasOwnStories) {
      final currentUser = context.read<HomeCubit>().currentUserData;
      return AppAvatar(
        imageUrl: currentUser?.imageUrl,
        size: 50,
        borderColor: Theme.of(context).primaryColor.withValues(alpha: 0.5),
        borderWidth: 2,
      );
    }

    return Container(
      height: 50,
      width: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).primaryColor.withValues(alpha: 0.8),
        border:
            widget.story == null
                ? null
                : Border.all(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
                  width: 2,
                ),
      ),
      child: CircleAvatar(
        radius: 8,
        backgroundColor:
            widget.story == null
                ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
                : widget.story!.storyType == StoryType.video
                ? Colors.black
                : (widget.story!.imageUrl == null &&
                    widget.story!.videoUrl == null &&
                    widget.story!.backgroundColor != null)
                ? Color(int.parse(widget.story!.backgroundColor!, radix: 16))
                : AppColors.transparent,
        backgroundImage:
            widget.story?.imageUrl == null
                ? null
                : NetworkImage(widget.story!.imageUrl!),
        child:
            widget.story == null
                ? BlocBuilder<StoriesCubit, StoriesState>(
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
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                )
                : null,
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String? currentUserId) {
    String text;
    if (widget.isOwnTile) {
      text = _hasOwnStories ? 'My Story' : 'Share Story';
    } else if (widget.story == null) {
      text = 'Share Story';
    } else {
      text =
          widget.story!.authorId == currentUserId
              ? 'You'
              : widget.story!.authorName.split(' ').first;
    }

    return Text(
      text,
      textAlign: TextAlign.start,
      style: Theme.of(context).textTheme.titleSmall!.copyWith(
        fontSize: 13,
        fontWeight:
            widget.isOwnTile && !_hasOwnStories
                ? FontWeight.w300
                : FontWeight.w400,
      ),
    );
  }
}
