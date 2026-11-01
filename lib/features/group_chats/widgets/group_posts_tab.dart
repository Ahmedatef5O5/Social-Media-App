import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/empty_findings_animation_widget.dart';
import '../../home/cubits/home_cubit/home_cubit.dart';
import '../../posts/cubits/posts_cubit/posts_cubit.dart';
import '../../posts/helpers/posts_skeleton_items.dart';
import '../../posts/widgets/post_item_widget.dart';
import '../cubits/group_feed_cubit/group_feed_cubit.dart';
import '../models/group_profile_model.dart';
import 'group_view_header.dart';

/// Tab 1 of GroupView: inline composer + the group's feed (PostItemWidget),
/// with pull-to-refresh, pagination and an empty state.
class GroupPostsTab extends StatelessWidget {
  final GroupProfileModel profile;
  final PostsCubit postsCubit;
  final VoidCallback onNewPost;

  const GroupPostsTab({
    super.key,
    required this.profile,
    required this.postsCubit,
    required this.onNewPost,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return BlocBuilder<GroupFeedCubit, GroupFeedState>(
      builder: (context, feedState) {
        if (feedState is GroupFeedError) {
          return _scrollable(
            context,
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(feedState.message),
                CupertinoButton(
                  onPressed: () => context.read<GroupFeedCubit>().loadInitial(),
                  child: Text(context.l10n.retry),
                ),
              ],
            ),
          );
        }
        if (feedState is! GroupFeedLoaded) {
          return PostsSkeletonItems(bottomPadding: bottomInset);
        }

        final composer = _Composer(profile: profile, onTap: onNewPost);

        if (feedState.postIds.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => context.read<GroupFeedCubit>().refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                composer,
                const Gap(24),
                const Center(
                  child: EmptyFindingsThemedAnimation(
                    animationPath: AppImages.emptyFindingsLot,
                    width: 150,
                    height: 150,
                  ),
                ),
                const Gap(8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    context.l10n.beFirstToPost,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return BlocBuilder<PostsCubit, PostsState>(
          buildWhen: (_, current) => current is PostsLoaded,
          builder: (context, state) {
            final feed =
                state is PostsLoaded ? state.posts : postsCubit.cachedPosts;
            final byId = {for (final p in feed) p.id: p};
            final posts = [
              for (final id in feedState.postIds)
                if (byId[id] != null) byId[id]!,
            ];
            if (posts.isEmpty) {
              return PostsSkeletonItems(bottomPadding: bottomInset);
            }

            return NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n.metrics.axis == Axis.vertical &&
                    n.metrics.extentAfter < 600) {
                  context.read<GroupFeedCubit>().loadMore();
                }
                return false;
              },
              child: RefreshIndicator(
                onRefresh: () => context.read<GroupFeedCubit>().refresh(),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: ClampingScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(child: composer),
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
                    if (feedState.isLoadingMore)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 20),
                          child: Center(child: CupertinoActivityIndicator()),
                        ),
                      ),
                    SliverGap(bottomInset + 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _scrollable(BuildContext context, Widget child) {
    return LayoutBuilder(
      builder:
          (context, c) => SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight),
              child: Center(child: child),
            ),
          ),
    );
  }
}

class _Composer extends StatelessWidget {
  final GroupProfileModel profile;
  final VoidCallback onTap;
  const _Composer({required this.profile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (!profile.isMember) return const SizedBox.shrink();
    if (!profile.canPost) return const GroupPostingRestrictedBanner();

    final theme = Theme.of(context);
    final avatar = context.read<HomeCubit>().currentUserData?.imageUrl;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                AppAvatar(imageUrl: avatar, size: 36),
                const Gap(12),
                Expanded(
                  child: Text(
                    context.l10n.writeInGroupHint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: context.ls(0),
                    ),
                  ),
                ),
                Icon(Icons.image_outlined, color: theme.primaryColor, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
