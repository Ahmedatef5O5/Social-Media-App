import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/features/home/cubit/home_cubit.dart';
import 'package:social_media_app/features/home/widgets/story_item_widget.dart';
import '../../../core/themes/app_colors.dart';

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
        listenWhen: (previous, current) => current is StoriesError,
        listener: (context, state) {
          if (state is StoriesError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: ${state.message}')));
          }
        },
        buildWhen:
            (previous, current) =>
                current is StoriesLoaded ||
                current is StoriesLoading ||
                current is StoriesError,
        builder: (context, state) {
          if (state is StoriesLoading) {
            return const Center(
              child: CupertinoActivityIndicator(color: AppColors.black12),
            );
          } else if (state is StoriesLoaded) {
            final stories = state.stories;
            return ListView.builder(
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              itemCount: stories.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: StoryItemWidget(),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: StoryItemWidget(story: stories[index - 1]),
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
