import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../cubits/posts_cubit/posts_cubit.dart';
import 'post_item_widget.dart';

class PostsSection extends StatelessWidget {
  const PostsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final postsCubit = context.read<PostsCubit>();
    return BlocBuilder<PostsCubit, PostsState>(
      bloc: postsCubit,
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

          debugPrint(
            '🔄 PostsSection Rebuilt! Total posts now: \${posts.length}',
          );

          if (posts.isEmpty) {
            return SliverToBoxAdapter(
              child: const Center(child: Text('No posts available.')),
            );
          }
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final post = posts[index];

                return Padding(
                  key: ValueKey(post.id),
                  padding: EdgeInsets.only(
                    bottom: index == posts.length - 1 ? 0 : 14.0,
                  ),
                  child: PostItemWidget(
                    key: ValueKey(posts[index].id),
                    currPost: post,
                    postsCubit: postsCubit,
                  ),
                );
              },
              childCount: posts.length,

              findChildIndexCallback: (Key key) {
                final valueKey = key as ValueKey<String>;
                final index = posts.indexWhere((p) => p.id == valueKey.value);
                return index >= 0 ? index : null;
              },
            ),
          );
        } else if (state is PostsError) {
          return SliverToBoxAdapter(child: Center(child: Text(state.message)));
        }
        return SliverToBoxAdapter(child: const SizedBox.shrink());
      },
    );
  }
}
