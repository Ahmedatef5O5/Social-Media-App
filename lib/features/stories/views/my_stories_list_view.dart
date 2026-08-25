import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/features/settings/repository/settings_repository.dart';
import 'package:social_media_app/features/social_graph/models/content_privacy.dart';
import 'package:social_media_app/features/social_graph/widgets/privacy_selector_sheet.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/toast/app_toast.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../cubit/my_stories_cubit/my_stories_cubit.dart';
import '../cubit/stories_cubit/stories_cubit.dart';
import '../helpers/story_creation_launcher.dart';
import '../model/story_model.dart';
import '../widgets/my_story_tile.dart';
import '../widgets/story_delete_dialog.dart';

class MyStoriesListView extends StatefulWidget {
  final StoriesCubit storiesCubit;
  final List<StoryModel> myStories;

  const MyStoriesListView({
    super.key,
    required this.storiesCubit,
    required this.myStories,
  });

  @override
  State<MyStoriesListView> createState() => _MyStoriesListViewState();
}

class _MyStoriesListViewState extends State<MyStoriesListView> {
  Offset _fabPosition = Offset.zero;
  bool _isFabPositionInitialized = false;

  Future<void> _openDefaultStoryPrivacySettings(BuildContext context) async {
    final currentPrivacy = SettingsRepository.instance.defaultStoryPrivacy;
    final result = await showPrivacySelectorSheet(
      context,
      currentPrivacy: currentPrivacy,
      isStory: true,
    );
    if (result == null) return;
    await SettingsRepository.instance.setDefaultStoryPrivacy(result);
    if (context.mounted) {
      AppToast.success('Default story privacy set to ${result.label}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider(
      create:
          (_) => MyStoriesCubit(
            initialStories: widget.myStories,
            storiesCubit: widget.storiesCubit,
          ),
      child: BlocListener<StoriesCubit, StoriesState>(
        bloc: widget.storiesCubit,
        listenWhen:
            (_, current) =>
                current is StoryImagePicked || current is StoryVideoPicked,
        listener: (context, state) {
          if (ModalRoute.of(context)?.isCurrent != true) return;

          if (state is StoryImagePicked) {
            StoryCreationLauncher.navigateToPreview(
              context: context,
              storiesCubit: widget.storiesCubit,
              file: state.file,
              isVideo: false,
            );
          } else if (state is StoryVideoPicked) {
            StoryCreationLauncher.navigateToPreview(
              context: context,
              storiesCubit: widget.storiesCubit,
              file: state.file,
              isVideo: true,
              videoDuration: state.videoDuration,
            );
          }
        },
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: LayoutBuilder(
            builder: (context, constraints) {
              if (!_isFabPositionInitialized) {
                _fabPosition = Offset(
                  constraints.maxWidth - 60 - 24,
                  constraints.maxHeight - 60 - 32,
                );
                _isFabPositionInitialized = true;
              }
              return Stack(
                children: [
                  BlocConsumer<MyStoriesCubit, MyStoriesState>(
                    listener: (context, state) {
                      if (ModalRoute.of(context)?.isCurrent != true) return;
                      final loaded = state as MyStoriesLoaded;
                      if (loaded.stories.isEmpty) Navigator.pop(context);
                    },
                    builder: (context, state) {
                      final loaded = state as MyStoriesLoaded;

                      return CustomScrollView(
                        slivers: [
                          SliverAppBar(
                            floating: true,
                            snap: true,
                            elevation: 0,
                            scrolledUnderElevation: 0,
                            backgroundColor: theme.scaffoldBackgroundColor,
                            leading: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              transitionBuilder:
                                  (child, anim) => ScaleTransition(
                                    scale: anim,
                                    child: FadeTransition(
                                      opacity: anim,
                                      child: child,
                                    ),
                                  ),
                              child:
                                  loaded.isSelectionMode
                                      ? InkWell(
                                        key: const ValueKey('selection-close'),
                                        onTap:
                                            () =>
                                                context
                                                    .read<MyStoriesCubit>()
                                                    .clearSelection(),
                                        borderRadius: BorderRadius.circular(50),
                                        child: Icon(
                                          Icons.close_rounded,
                                          color: theme.primaryColor,
                                          size: 24,
                                        ),
                                      )
                                      : InkWell(
                                        key: const ValueKey('back-arrow'),
                                        onTap:
                                            () => Navigator.of(context).pop(),
                                        borderRadius: BorderRadius.circular(50),
                                        child: Icon(
                                          Icons.arrow_back_ios_new_rounded,
                                          color: theme.primaryColor,
                                          size: 20,
                                        ),
                                      ),
                            ),
                            titleSpacing: 0,
                            title: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: Text(
                                loaded.isSelectionMode
                                    ? '${loaded.selectedStoryIds.length} selected'
                                    : 'My Stories',
                                key: ValueKey(loaded.isSelectionMode),
                                style: theme.textTheme.titleMedium!.copyWith(
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            actions: [
                              if (!loaded.isSelectionMode &&
                                  loaded.stories.isNotEmpty)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 3.0,
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          '${loaded.stories.length}',
                                          style: TextStyle(
                                            color: theme.primaryColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                        const SizedBox(width: 6),

                                        Image.asset(
                                          AppImages.storyIcon,
                                          width: 20,
                                          height: 20,
                                          fit: BoxFit.contain,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                transitionBuilder:
                                    (child, anim) => ScaleTransition(
                                      scale: anim,
                                      child: FadeTransition(
                                        opacity: anim,
                                        child: child,
                                      ),
                                    ),
                                child:
                                    loaded.isSelectionMode
                                        ? IconButton(
                                          key: const ValueKey(
                                            'bulk-delete-action',
                                          ),
                                          icon: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withValues(
                                                alpha: 0.1,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.delete_outline_rounded,
                                              color: Colors.redAccent,
                                            ),
                                          ),
                                          onPressed: () async {
                                            final cubit =
                                                context.read<MyStoriesCubit>();
                                            final currentState =
                                                cubit.state as MyStoriesLoaded;
                                            final confirm =
                                                await showDeleteStoryDialog(
                                                  context,
                                                  count:
                                                      currentState
                                                          .selectedStoryIds
                                                          .length,
                                                );
                                            if (confirm == true) {
                                              cubit.deleteSelectedStories();
                                            }
                                          },
                                        )
                                        : IconButton(
                                          onPressed:
                                              () =>
                                                  _openDefaultStoryPrivacySettings(
                                                    context,
                                                  ),
                                          color: theme.primaryColor,
                                          icon: Icon(
                                            Icons.privacy_tip_outlined,
                                            size: 20,
                                          ),
                                        ),
                              ),
                            ],
                          ),

                          if (loaded.stories.isEmpty)
                            const SliverFillRemaining(
                              child: Center(child: CustomLoadingIndicator()),
                            )
                          else
                            SliverPadding(
                              padding: const EdgeInsets.only(
                                top: 12,
                                bottom: 100,
                              ),
                              sliver: SliverList.builder(
                                itemCount: loaded.stories.length,
                                itemBuilder: (context, index) {
                                  final story = loaded.stories[index];
                                  final isDeleted = loaded.deletingStoryIds
                                      .contains(story.id);
                                  final isSelected = loaded.selectedStoryIds
                                      .contains(story.id);

                                  return MyStoryTile(
                                    key: ValueKey(story.id),
                                    story: story,
                                    stat: loaded.statsByStoryId[story.id],
                                    isDeleting: isDeleted,
                                    isSelectionMode: loaded.isSelectionMode,
                                    isSelected: isSelected,
                                    storiesCubit: widget.storiesCubit,
                                    onTap: () {
                                      if (loaded.isSelectionMode) {
                                        context
                                            .read<MyStoriesCubit>()
                                            .toggleSelection(story.id);
                                        return;
                                      }
                                      Navigator.of(
                                        context,
                                        rootNavigator: true,
                                      ).pushNamed(
                                        AppRoutes.storyDisplayViewRoute,
                                        arguments: {
                                          'storiesCubit': widget.storiesCubit,
                                          'allUserGroups': [loaded.stories],
                                          'initialGroupIndex': 0,
                                          'initialStoryIndex': index,
                                        },
                                      );
                                    },
                                    onLongPress: () {
                                      if (!loaded.isSelectionMode) {
                                        context
                                            .read<MyStoriesCubit>()
                                            .enterSelectionMode(story.id);
                                      }
                                    },
                                    onDelete: () async {
                                      final confirm =
                                          await showDeleteStoryDialog(context);
                                      if (confirm == true && context.mounted) {
                                        context
                                            .read<MyStoriesCubit>()
                                            .deleteStory(story.id);
                                      }
                                    },
                                  );
                                },
                              ),
                            ),
                        ],
                      );
                    },
                  ),

                  Positioned(
                    left: _fabPosition.dx,
                    top: _fabPosition.dy,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          _fabPosition = Offset(
                            (_fabPosition.dx + details.delta.dx).clamp(
                              16.0,
                              constraints.maxWidth - 60 - 16.0,
                            ),
                            (_fabPosition.dy + details.delta.dy).clamp(
                              16.0,
                              constraints.maxHeight - 60 - 16.0,
                            ),
                          );
                        });
                      },
                      onTap: () {
                        StoryCreationLauncher.openPicker(
                          context,
                          widget.storiesCubit,
                        );
                      },
                      child: _buildDraggableFAB(theme),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDraggableFAB(ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: theme.primaryColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.25),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(
        Icons.add_to_photos_rounded,
        color: Colors.white,
        size: 26,
      ),
    );
  }
}
