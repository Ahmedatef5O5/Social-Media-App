import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/features/home/cubit/home_cubit.dart';
import 'package:social_media_app/features/home/widgets/story_item_widget.dart';
import '../../../core/router/app_routes.dart';
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
            (previous, current) =>
                current is StoriesError || current is StoryImagePicked,
        listener: (context, state) {
          if (state is StoriesError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: ${state.message}')));
          }
          if (state is StoryImagePicked) {
            Navigator.of(context, rootNavigator: true).pushNamed(
              AppRoutes.addStoryCaptionViewRoute,
              arguments: {
                'file': state.file,
                'homeCubit': context.read<HomeCubit>(),
              },
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
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              // physics: const AlwaysScrollableScrollPhysics(),
              primary: false,
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
