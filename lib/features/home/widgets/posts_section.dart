import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import 'package:social_media_app/features/home/cubit/home_cubit.dart';

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
          return const Center(
            child: CupertinoActivityIndicator(color: AppColors.black12),
          );
        } else if (state is PostsLoaded) {
          final posts = state.posts;
          if (posts.isEmpty) {
            return const Center(child: Text('No posts available.'));
          }
          return ListView.builder(
            itemCount: posts.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final post = posts[index];

              return PostItemWidget(post: post);
            },
          );
        } else if (state is PostsError) {
          return Center(child: Text(state.message));
        }
        return const SizedBox.shrink();
      },
    );
  }
}
