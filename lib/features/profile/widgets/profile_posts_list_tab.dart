import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../../home/cubit/home_cubit.dart';
import '../../home/widgets/post_item_widget.dart';

class ProfilePostsListTab extends StatefulWidget {
  final String userId;
  final ValueNotifier<double> refreshProgress;
  final ValueNotifier<bool> isRefreshing;

  const ProfilePostsListTab({
    super.key,
    required this.userId,
    required this.refreshProgress,
    required this.isRefreshing,
  });

  @override
  State<ProfilePostsListTab> createState() => _ProfilePostsListTabState();
}

class _ProfilePostsListTabState extends State<ProfilePostsListTab> {
  @override
  void initState() {
    super.initState();
    final homeCubit = context.read<HomeCubit>();
    if (homeCubit.state is! PostsLoaded) {
      homeCubit.fetchPosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state is PostsLoaded) {
          final userPosts =
              state.posts.where((p) => p.authorId == widget.userId).toList();

          if (userPosts.isEmpty) {
            return const Center(child: Text('No posts yet'));
          }
          return CustomScrollView(
            physics: AlwaysScrollableScrollPhysics(
              parent: ClampingScrollPhysics(),
            ),
            // primary: false,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final post = userPosts[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: PostItemWidget(currPost: post),
                    );
                  }, childCount: userPosts.length),
                ),
              ),

              SliverGap(MediaQuery.of(context).padding.bottom + 60),
            ],
          );
        }
        return const CustomLoadingIndicator();
      },
    );
  }
}
