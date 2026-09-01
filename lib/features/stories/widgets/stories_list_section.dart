import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/features/stories/models/story_model.dart';
import 'package:social_media_app/features/stories/widgets/story_item_widget.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/toast/app_toast.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../cubits/stories_cubit/stories_cubit.dart';
import 'story_card_widget.dart';

class StoriesListSection extends StatelessWidget {
  const StoriesListSection({super.key});

  @override
  Widget build(BuildContext context) {
    final storiesCubit = BlocProvider.of<StoriesCubit>(context);
    final currentUserId = SupabaseProvider.idOrNull;

    if (currentUserId == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: StoryCardWidget.cardHeight + 24,

      child: BlocConsumer<StoriesCubit, StoriesState>(
        bloc: storiesCubit,
        listenWhen:
            (_, current) =>
                current is StoriesError ||
                current is StoryVideoTooLong ||
                current is StoryVideoPickError,
        listener: (context, state) {
          if (state is StoriesError) {
            AppToast.error('Error: ${state.message}');
          }
          if (state is StoryVideoTooLong) {
            AppToast.warning(
              'Video is ${state.videoDuration.inSeconds}s — '
              'max allowed is ${state.maxAllowed.inSeconds}s.',
            );
          }
          if (state is StoryVideoPickError) {
            AppToast.error('Error: ${state.message}');
          }
        },
        buildWhen:
            (previous, current) =>
                current is StoriesLoaded ||
                current is AddStoryLoading ||
                current is AddStorySuccess ||
                (current is StoriesLoading && previous is! StoriesLoaded),
        builder: (context, state) {
          final stories =
              state is StoriesLoaded
                  ? state.stories
                  : storiesCubit.cachedStories;
          if (stories.isEmpty) {
            if (state is StoriesLoading) return const CustomLoadingIndicator();
            return const SizedBox.shrink();
          }

          final activeStories = stories.where((s) => !s.isExpired).toList();

          final Map<String, List<StoryModel>> storiesByUser = {};
          for (final story in activeStories) {
            storiesByUser.putIfAbsent(story.authorId, () => []).add(story);
          }

          final myStories = storiesByUser.remove(currentUserId);
          final otherUsersGroups = storiesByUser.values.toList();

          final allGroupsForViewer = [
            if (myStories != null) myStories,
            ...otherUsersGroups,
          ];

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            primary: false,
            padding: const EdgeInsets.only(left: 4, right: 12),
            clipBehavior: Clip.none,
            itemCount: otherUsersGroups.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: StoryItemWidget(
                    isOwnTile: true,
                    userStroies: myStories,
                    allUserGroups: allGroupsForViewer,
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: StoryItemWidget(
                  story: otherUsersGroups[index - 1].first,
                  userStroies: otherUsersGroups[index - 1],
                  allUserGroups: allGroupsForViewer,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
