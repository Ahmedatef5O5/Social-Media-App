import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/features/home/cubits/home_cubit/home_cubit.dart';
import 'package:social_media_app/features/stories/model/story_model.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../posts/helper/global_video_pause_gate.dart';
import '../cubit/stories_cubit/stories_cubit.dart';
import '../helpers/story_creation_launcher.dart';
import 'create_story_card_widget.dart';
import 'story_card_widget.dart';

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

  Future<void> _navigateToPreview({
    required BuildContext context,
    required File file,
    required bool isVideo,
    Duration? videoDuration,
  }) async {
    if (_navigationHandled) return;
    _navigationHandled = true;
    GlobalVideoPauseGate.instance.isPaused.value = true;

    await StoryCreationLauncher.navigateToPreview(
      context: context,
      storiesCubit: context.read<StoriesCubit>(),
      file: file,
      isVideo: isVideo,
      videoDuration: videoDuration,
    );
    GlobalVideoPauseGate.instance.isPaused.value = false;
    _navigationHandled = false;
  }

  void _openMyStories(BuildContext context) async {
    GlobalVideoPauseGate.instance.isPaused.value = true;
    await Navigator.of(context, rootNavigator: true).pushNamed(
      AppRoutes.myStoriesListViewRoute,
      arguments: {
        'storiesCubit': context.read<StoriesCubit>(),
        'myStories': widget.userStroies,
      },
    );
    GlobalVideoPauseGate.instance.isPaused.value = false;
  }

  void _openOtherUserStory(BuildContext context) async {
    final storiesCubit = context.read<StoriesCubit>();
    final stories = widget.userStroies ?? [widget.story!];
    final groups = widget.allUserGroups ?? [stories];
    final groupIndex = groups.indexWhere(
      (g) => g.first.authorId == widget.story!.authorId,
    );
    GlobalVideoPauseGate.instance.isPaused.value = true;

    await Navigator.of(context, rootNavigator: true).pushNamed(
      AppRoutes.storyDisplayViewRoute,
      arguments: {
        'storiesCubit': storiesCubit,
        'allUserGroups': groups,
        'initialGroupIndex': groupIndex,
      },
    );
    GlobalVideoPauseGate.instance.isPaused.value = false;
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = SupabaseProvider.id;

    return BlocListener<StoriesCubit, StoriesState>(
      listenWhen:
          (_, current) =>
              widget.story == null &&
              (current is StoryImagePicked || current is StoryVideoPicked),
      listener: (context, state) {
        if (ModalRoute.of(context)?.isCurrent != true) return;
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
      child: _buildCard(context, currentUserId),
    );
  }

  Widget _buildCard(BuildContext context, String? currentUserId) {
    if (widget.isOwnTile && !_hasOwnStories) {
      return BlocBuilder<StoriesCubit, StoriesState>(
        buildWhen:
            (_, current) =>
                current is StoriesLoaded || current is AddStoryError,
        builder: (context, state) {
          final currentUser = context.read<HomeCubit>().currentUserData;
          final storiesCubit = context.read<StoriesCubit>();
          final isUploading = storiesCubit.cachedStories.any(
            (s) => s.authorId == currentUserId && s.isPendingUpload,
          );
          return CreateStoryCardWidget(
            avatarUrl: currentUser?.imageUrl,
            isUploading: isUploading,
            onTap: () => _showAddStoryOptions(context),
          );
        },
      );
    }

    if (widget.isOwnTile && _hasOwnStories) {
      return StoryCardWidget(
        story: widget.userStroies!.first,
        label: 'Your Story',
        onTap: () => _openMyStories(context),
        onAddTap: () => _showAddStoryOptions(context),
      );
    }

    return StoryCardWidget(
      story: widget.story!,
      label:
          widget.story!.authorId == currentUserId
              ? 'You'
              : widget.story!.authorName,
      onTap: () => _openOtherUserStory(context),
    );
  }
}
