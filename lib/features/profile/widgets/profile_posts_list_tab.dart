import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/widgets/empty_findings_animation_widget.dart';
import '../../posts/cubits/posts_cubit/posts_cubit.dart';
import '../../posts/helpers/posts_skeleton_items.dart';
import '../../posts/widgets/post_item_widget.dart';
import '../cubits/profile_posts_cubit/profile_posts_cubit.dart';

class ProfilePostsListTab extends StatelessWidget {
  final PostsCubit postsCubit;
  final String userId;
  final ValueNotifier<double> refreshProgress;
  final ValueNotifier<bool> isRefreshing;
  final bool isCurrentUser;

  const ProfilePostsListTab({
    super.key,
    required this.postsCubit,
    required this.userId,
    required this.refreshProgress,
    required this.isRefreshing,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return BlocBuilder<ProfilePostsCubit, ProfilePostsState>(
      builder: (context, profileState) {
        if (profileState is ProfilePostsError) {
          return _buildCenteredScrollable(
            context,
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(profileState.message),
                CupertinoButton(
                  onPressed:
                      () => context.read<ProfilePostsCubit>().loadInitial(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        if (profileState is! ProfilePostsLoaded) {
          return PostsSkeletonItems(
            bottomPadding: isCurrentUser ? bottomInset + 65 : 0,
          );
        }
        if (profileState.postIds.isEmpty) {
          final theme = Theme.of(context);
          return _buildCenteredScrollable(
            context,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const EmptyFindingsThemedAnimation(
                    animationPath: AppImages.emptyFindingsLot,
                    width: 160,
                    height: 160,
                  ),
                  const Gap(12),
                  Text(
                    isCurrentUser ? 'No posts to show yet' : 'No posts yet',
                    style: theme.textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Gap(6),
                  Text(
                    isCurrentUser
                        ? 'Share your thoughts with your friends.'
                        : 'This person hasn’t shared anything yet.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return BlocBuilder<PostsCubit, PostsState>(
          buildWhen: (_, current) => current is PostsLoaded,
          builder: (context, feedState) {
            final feed =
                feedState is PostsLoaded
                    ? feedState.posts
                    : postsCubit.cachedPosts;
            final byId = {for (final p in feed) p.id: p};
            final posts = [
              for (final id in profileState.postIds)
                if (byId[id] != null) byId[id]!,
            ];

            if (posts.isEmpty) {
              return PostsSkeletonItems(
                bottomPadding: isCurrentUser ? bottomInset + 65 : 0,
              );
            }

            return NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n.metrics.axis == Axis.vertical &&
                    n.metrics.extentAfter < 600) {
                  context.read<ProfilePostsCubit>().loadMore();
                }
                return false; // keep bubbling (back-to-top listener)
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final post = posts[index];
                          return Padding(
                            key: ValueKey(post.id),
                            padding: const EdgeInsets.only(bottom: 20),
                            child: PostItemWidget(
                              currPost: post,
                              postsCubit: postsCubit,
                              isProfileContext: true,
                            ),
                          );
                        },
                        childCount: posts.length,
                        findChildIndexCallback: (Key key) {
                          final id = (key as ValueKey<String>).value;
                          final index = posts.indexWhere((p) => p.id == id);
                          return index >= 0 ? index : null;
                        },
                      ),
                    ),
                  ),
                  if (profileState.isLoadingMore)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 20),
                        child: Center(child: CupertinoActivityIndicator()),
                      ),
                    ),
                  if (isCurrentUser) SliverGap(bottomInset + 60),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCenteredScrollable(BuildContext context, Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: child),
          ),
        );
      },
    );
  }
}
