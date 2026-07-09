import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../cubit/my_stories_cubit/my_stories_cubit.dart';
import '../cubit/stories_cubit/stories_cubit.dart';
import '../helpers/story_creation_launcher.dart';
import '../model/story_model.dart';
import '../widgets/my_story_tile.dart';
import '../widgets/story_delete_dialog.dart';

class MyStoriesListView extends StatelessWidget {
  final StoriesCubit storiesCubit;
  final List<StoryModel> myStories;

  const MyStoriesListView({
    super.key,
    required this.storiesCubit,
    required this.myStories,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (_) => MyStoriesCubit(
            initialStories: myStories,
            storiesCubit: storiesCubit,
          ),
      child: BlocListener<StoriesCubit, StoriesState>(
        bloc: storiesCubit,
        listenWhen:
            (_, current) =>
                current is StoryImagePicked || current is StoryVideoPicked,
        listener: (context, state) {
          if (state is StoryImagePicked) {
            StoryCreationLauncher.navigateToPreview(
              context: context,
              storiesCubit: storiesCubit,
              file: state.file,
              isVideo: false,
            );
          } else if (state is StoryVideoPicked) {
            StoryCreationLauncher.navigateToPreview(
              context: context,
              storiesCubit: storiesCubit,
              file: state.file,
              isVideo: true,
              videoDuration: state.videoDuration,
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('My Stories')),
          body: BlocConsumer<MyStoriesCubit, MyStoriesState>(
            listener: (context, state) {
              final loaded = state as MyStoriesLoaded;
              if (loaded.stories.isEmpty) Navigator.pop(context);
            },
            builder: (context, state) {
              final loaded = state as MyStoriesLoaded;

              if (loaded.stories.isEmpty) {
                return const Center(child: CustomLoadingIndicator());
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: loaded.stories.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
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
                            'storiesCubit': storiesCubit,
                            'allUserGroups': [loaded.stories],
                            'initialGroupIndex': 0,
                            'initialStoryIndex': index,
                          },
                        ),
                    onDelete: () async {
                      final confirm = await showDeleteStoryDialog(context);
                      if (confirm == true && context.mounted) {
                        context.read<MyStoriesCubit>().deleteStory(story.id);
                      }
                    },
                  );
                },
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed:
                () => StoryCreationLauncher.openPicker(context, storiesCubit),
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}
