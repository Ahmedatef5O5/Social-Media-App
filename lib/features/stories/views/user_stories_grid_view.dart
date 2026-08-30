import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/themes/app_colors.dart';
import '../cubits/my_stories_cubit/my_stories_cubit.dart';
import '../cubits/stories_cubit/stories_cubit.dart';
import '../helpers/stories_grid_skeleton.dart';
import '../models/story_model.dart';
import '../models/story_stat_model.dart';
import '../services/stories_services.dart';
import '../widgets/story_grid_tile.dart';

class UserStoriesGridView extends StatelessWidget {
  final String userId;
  final String authorName;
  final StoriesCubit storiesCubit;

  const UserStoriesGridView({
    super.key,
    required this.userId,
    required this.authorName,
    required this.storiesCubit,
  });

  bool get _isMe => userId == SupabaseProvider.id;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              floating: true,
              snap: true,
              elevation: 0,
              scrolledUnderElevation: 0,
              shadowColor: Colors.transparent,
              backgroundColor: theme.scaffoldBackgroundColor,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              titleSpacing: 0,
              title: Text(
                _isMe ? 'My Stories' : "$authorName's Stories",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Builder(
                    builder: (context) {
                      final int storyCount =
                          _isMe
                              ? storiesCubit.cachedStories
                                  .where((s) => s.authorId == userId)
                                  .length
                              : 0;

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (storyCount > 0) ...[
                            Text(
                              '$storyCount',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],

                          ClipOval(
                            child: Image.asset(
                              AppImages.storyIcon,
                              width: 23,
                              height: 23,
                              fit: BoxFit.contain,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ];
        },

        body:
            _isMe ? _buildMyStoriesGrid(context) : _buildOtherUserGrid(context),
      ),
    );
  }

  Widget _buildMyStoriesGrid(BuildContext context) {
    return BlocProvider(
      create:
          (_) => MyStoriesCubit(
            initialStories:
                storiesCubit.cachedStories
                    .where((s) => s.authorId == userId)
                    .toList(),
            storiesCubit: storiesCubit,
          ),
      child: BlocBuilder<MyStoriesCubit, MyStoriesState>(
        builder: (context, state) {
          final loaded = state as MyStoriesLoaded;
          return _StoriesGridBody(
            stories: loaded.stories,
            statsByStoryId: loaded.statsByStoryId,
            showAnalytics: true,
            storiesCubit: storiesCubit,
          );
        },
      ),
    );
  }

  Widget _buildOtherUserGrid(BuildContext context) {
    return FutureBuilder<List<StoryModel>>(
      future: StoriesServices().getAuthorStories(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const StoriesGridSkeleton();
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Could not load stories',
              style: TextStyle(color: AppColors.grey5),
            ),
          );
        }
        final stories = snapshot.data ?? const <StoryModel>[];
        return _StoriesGridBody(
          stories: stories,
          statsByStoryId: const {},
          showAnalytics: false,
          storiesCubit: storiesCubit,
        );
      },
    );
  }
}

class _StoriesGridBody extends StatelessWidget {
  final List<StoryModel> stories;
  final Map<String, StoryStatModel> statsByStoryId;
  final bool showAnalytics;
  final StoriesCubit storiesCubit;

  const _StoriesGridBody({
    required this.stories,
    required this.statsByStoryId,
    required this.showAnalytics,
    required this.storiesCubit,
  });

  @override
  Widget build(BuildContext context) {
    if (stories.isEmpty) {
      return Center(
        child: Text(
          'No stories yet',
          style: TextStyle(color: AppColors.grey5, fontSize: 15),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 0.62,
      ),
      itemCount: stories.length,
      itemBuilder: (context, index) {
        final story = stories[index];
        return StoryGridTile(
          story: story,
          stat: statsByStoryId[story.id],
          showAnalytics: showAnalytics,
          onTap: () {
            Navigator.of(context, rootNavigator: true).pushNamed(
              AppRoutes.storyDisplayViewRoute,
              arguments: {
                'storiesCubit': storiesCubit,
                'allUserGroups': [stories],
                'initialGroupIndex': 0,
                'initialStoryIndex': index,
              },
            );
          },
        );
      },
    );
  }
}
