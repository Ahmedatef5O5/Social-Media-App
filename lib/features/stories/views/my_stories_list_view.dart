import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import '../../../core/router/app_routes.dart';
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
          appBar: AppBar(
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: theme.scaffoldBackgroundColor,
            leading: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(50),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: theme.primaryColor,
                size: 22,
              ),
            ),
            title: Text(
              'My Stories',
              style: theme.textTheme.titleMedium!.copyWith(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                fontSize: 20,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.more_vert_rounded, color: theme.primaryColor),
                onPressed: () {},
              ),
              const Gap(8),
            ],
          ),
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
                      final loaded = state as MyStoriesLoaded;
                      if (loaded.stories.isEmpty) Navigator.pop(context);
                    },
                    builder: (context, state) {
                      final loaded = state as MyStoriesLoaded;

                      if (loaded.stories.isEmpty) {
                        return const Center(child: CustomLoadingIndicator());
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.only(top: 12, bottom: 100),
                        itemCount: loaded.stories.length,
                        itemBuilder: (context, index) {
                          final story = loaded.stories[index];
                          return MyStoryTile(
                            story: story,
                            stat: loaded.statsByStoryId[story.id],
                            isDeleting: loaded.deletingStoryId == story.id,
                            onTap:
                                () => Navigator.of(
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
                                ),
                            onDelete: () async {
                              final confirm = await showDeleteStoryDialog(
                                context,
                              );
                              if (confirm == true && context.mounted) {
                                context.read<MyStoriesCubit>().deleteStory(
                                  story.id,
                                );
                              }
                            },
                          );
                        },
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
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: theme.primaryColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.4),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 6),
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
