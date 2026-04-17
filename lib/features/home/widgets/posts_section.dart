import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/features/home/cubits/home_cubit/home_cubit.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import 'post_item_widget.dart';

class PostsSection extends StatelessWidget {
  const PostsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final homeCubit = context.read<HomeCubit>();
    return BlocBuilder<HomeCubit, HomeState>(
      bloc: homeCubit,
      buildWhen:
          (previous, current) =>
              current is PostsLoading ||
              current is PostsLoaded ||
              current is PostsError,
      builder: (context, state) {
        if (state is PostsLoading) {
          return SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.36,
              child: const CustomLoadingIndicator(radius: 11),
            ),
          );
        } else if (state is PostsLoaded) {
          final posts = state.posts;
          if (posts.isEmpty) {
            return SliverToBoxAdapter(
              child: const Center(child: Text('No posts available.')),
            );
          }
          return SliverList.separated(
            itemCount: posts.length,

            itemBuilder: (context, index) {
              final post = posts[index];

              return PostItemWidget(
                key: ValueKey(posts[index].id),
                currPost: post,
                homeCubit: homeCubit,
              );
            },
            separatorBuilder:
                (BuildContext context, int index) => const Gap(14),
          );
        } else if (state is PostsError) {
          return SliverToBoxAdapter(child: Center(child: Text(state.message)));
        }
        return SliverToBoxAdapter(child: const SizedBox.shrink());
      },
    );
  }
}
