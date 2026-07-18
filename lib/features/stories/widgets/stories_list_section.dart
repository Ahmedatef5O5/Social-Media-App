import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/features/stories/model/story_model.dart';
import 'package:social_media_app/features/stories/widgets/story_item_widget.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/toast/app_toast.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../cubit/stories_cubit/stories_cubit.dart';

class StoriesListSection extends StatelessWidget {
  const StoriesListSection({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final storiesCubit = BlocProvider.of<StoriesCubit>(context);
    final currentUserId = SupabaseProvider.id;

    return SizedBox(
      height: size.height * 0.125,
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
                (current is StoriesLoading && previous is! StoriesLoaded),
        builder: (context, state) {
          if (state is StoriesLoading) {
            return const CustomLoadingIndicator();
          } else if (state is StoriesLoaded) {
            final activeStories =
                state.stories.where((s) => !s.isExpired).toList();

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
              itemCount: otherUsersGroups.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: StoryItemWidget(
                      isOwnTile: true,
                      userStroies: myStories,
                      allUserGroups: allGroupsForViewer,
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(left: 5, right: 11),
                  child: StoryItemWidget(
                    story: otherUsersGroups[index - 1].first,
                    userStroies: otherUsersGroups[index - 1],
                    allUserGroups: allGroupsForViewer,
                  ),
                );
              },
            );
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }
}
