import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/features/home/cubits/home_cubit/home_cubit.dart';
import 'package:social_media_app/features/home/models/story_model.dart';
import 'package:social_media_app/features/home/widgets/story_item_widget.dart';
import '../../../core/widgets/custom_loading_indicator.dart';

class StoriesListSection extends StatelessWidget {
  const StoriesListSection({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final homeCubit = BlocProvider.of<HomeCubit>(context);

    return SizedBox(
      height: size.height * 0.12,
      child: BlocConsumer<HomeCubit, HomeState>(
        bloc: homeCubit,
        listenWhen:
            (_, current) =>
                current is StoriesError ||
                current is StoryVideoTooLong ||
                current is StoryVideoPickError,
        listener: (context, state) {
          if (state is StoriesError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: ${state.message}')));
          }
          if (state is StoryVideoTooLong) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Video is ${state.videoDuration.inSeconds}s — '
                  'max allowed is ${state.maxAllowed.inSeconds}s.',
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          if (state is StoryVideoPickError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
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
            final stories = state.stories;

            final Map<String, List<StoryModel>> storiesByUser = {};
            for (final story in stories) {
              storiesByUser.putIfAbsent(story.authorId, () => []).add(story);
            }
            final uniqueUsers = storiesByUser.values.toList();

            return ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              primary: false,
              itemCount: uniqueUsers.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const Padding(
                    padding: EdgeInsets.only(right: 14),
                    child: StoryItemWidget(),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: StoryItemWidget(
                    story: uniqueUsers[index - 1].first,
                    userStroies: uniqueUsers[index - 1],
                    allUserGroups: uniqueUsers,
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
