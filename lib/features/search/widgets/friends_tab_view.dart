import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/widgets/custom_pull_to_refresh.dart';
import '../../../core/widgets/empty_findings_animation_widget.dart';
import '../../social_graph/cubits/friend_lists_cubit/friends_list_cubit.dart';
import '../../social_graph/models/friend_list_item_model.dart';
import '../../social_graph/widgets/friend_tile_widget.dart';
import '../../social_graph/widgets/friends_list_skeleton.dart';
import '../cubits/search_friends_cubit/search_friends_cubit.dart';
import '../utils/search_view_metrics.dart';

class FriendsTabView extends StatefulWidget {
  final ValueListenable<String> searchQuery;
  const FriendsTabView({super.key, required this.searchQuery});

  @override
  State<FriendsTabView> createState() => _FriendsTabViewState();
}

class _FriendsTabViewState extends State<FriendsTabView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    widget.searchQuery.addListener(_onQueryChanged);
  }

  void _onQueryChanged() {
    context.read<SearchFriendsCubit>().search(widget.searchQuery.value);
  }

  @override
  void dispose() {
    widget.searchQuery.removeListener(_onQueryChanged);
    super.dispose();
  }

  void _unfriend(BuildContext context, String friendshipId, bool isSearching) {
    context.read<FriendsListCubit>().unfriend(friendshipId);
    if (isSearching) {
      context.read<SearchFriendsCubit>().removeByFriendshipId(friendshipId);
    }
  }

  Widget _buildMutualFriendsPlaceholder() => const SizedBox.shrink();

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    final theme = Theme.of(context);

    return ValueListenableBuilder<String>(
      valueListenable: widget.searchQuery,
      builder: (context, query, _) {
        if (query.isNotEmpty) {
          return BlocBuilder<SearchFriendsCubit, SearchFriendsState>(
            builder:
                (context, state) =>
                    _buildSearchResults(context, theme, state, query),
          );
        }
        return BlocBuilder<FriendsListCubit, FriendsListState>(
          builder: (context, state) {
            if (state is FriendsListLoading || state is FriendsListInitial) {
              return const FriendsListSkeleton(isMe: true);
            }

            if (state is FriendsListError) {
              return _buildErrorState(
                context,
                theme,
                state.message,
                onRetry: () => context.read<FriendsListCubit>().loadFriends(),
              );
            }

            final friends = (state as FriendsListLoaded).friends;

            if (friends.isEmpty) {
              return _buildEmptyState(theme, '');
            }

            return Column(
              children: [
                _buildMutualFriendsPlaceholder(),
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification scrollInfo) {
                      if (scrollInfo.metrics.pixels >=
                          scrollInfo.metrics.maxScrollExtent - 200) {
                        context.read<FriendsListCubit>().loadMore();
                      }
                      return false;
                    },
                    child: CustomPullToRefresh(
                      onRefresh:
                          () => context.read<FriendsListCubit>().loadFriends(),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          SearchViewMetrics.horizontalPadding,
                          SearchViewMetrics.topGap,
                          SearchViewMetrics.horizontalPadding,
                          SearchViewMetrics.bottomGap,
                        ),
                        physics: const ClampingScrollPhysics(),
                        itemCount: friends.length,
                        separatorBuilder:
                            (_, __) => const Gap(SearchViewMetrics.itemGap),
                        itemBuilder: (context, i) {
                          final friend = friends[i];
                          return FriendTileWidget(
                            key: ValueKey(friend.friendshipId),
                            friend: friend,
                            isMe: true,
                            onUnfriend:
                                () => _unfriend(
                                  context,
                                  friend.friendshipId,
                                  false,
                                ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSearchResults(
    BuildContext context,
    ThemeData theme,
    SearchFriendsState state,
    String query,
  ) {
    if (state is SearchFriendsError) {
      return _buildErrorState(
        context,
        theme,
        state.message,
        onRetry: () => context.read<SearchFriendsCubit>().search(query),
      );
    }
    if (state is SearchFriendsInitial || state is SearchFriendsLoading) {
      return const FriendsListSkeleton(isMe: true);
    }

    final friends = (state as SearchFriendsLoaded).friends;
    if (friends.isEmpty) return _buildEmptyState(theme, query);

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels >=
            scrollInfo.metrics.maxScrollExtent - 200) {
          context.read<SearchFriendsCubit>().loadMore();
        }
        return false;
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          SearchViewMetrics.horizontalPadding,
          SearchViewMetrics.topGap,
          SearchViewMetrics.horizontalPadding,
          SearchViewMetrics.bottomGap,
        ),
        physics: const ClampingScrollPhysics(),
        itemCount: friends.length + (!state.hasReachedMax ? 1 : 0),
        separatorBuilder: (_, __) => const Gap(SearchViewMetrics.itemGap),
        itemBuilder: (context, i) {
          if (i >= friends.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          final FriendListItemModel friend = friends[i];
          return FriendTileWidget(
            key: ValueKey(friend.friendshipId),
            friend: friend,
            isMe: true,
            onUnfriend: () => _unfriend(context, friend.friendshipId, true),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const EmptyFindingsThemedAnimation(
              animationPath: AppImages.emptyFindingsLot,
              width: 150,
              height: 150,
            ),
            const Gap(12),
            Text(
              query.isEmpty
                  ? 'No friends yet'
                  : 'No friends found for "$query"',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (query.isEmpty) ...[
              const Gap(6),
              Text(
                'People you add as friends will show up here.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    ThemeData theme,
    String message, {
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 42,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const Gap(12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const Gap(14),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
