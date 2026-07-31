import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/widgets/custom_pull_to_refresh.dart';
import '../../../core/widgets/empty_findings_animation_widget.dart';
import '../../social_graph/cubit/friend_lists_cubit/friends_list_cubit.dart';
import '../../social_graph/widgets/friend_tile_widget.dart';
import '../../social_graph/widgets/friends_list_skeleton.dart';

class FriendsTabView extends StatefulWidget {
  const FriendsTabView({super.key});

  @override
  State<FriendsTabView> createState() => _FriendsTabViewState();
}

class _FriendsTabViewState extends State<FriendsTabView>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<FriendsListCubit>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Reserved slot for the future "Mutual Friends" section.
  /// When that lands, this becomes a small horizontal row/section
  /// (its own cubit field or a dedicated MutualFriendsCubit) rendered
  /// above the friends list — the ListView below stays untouched.
  Widget _buildMutualFriendsPlaceholder() => const SizedBox.shrink();

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    final theme = Theme.of(context);

    return BlocBuilder<FriendsListCubit, FriendsListState>(
      builder: (context, state) {
        if (state is FriendsListLoading || state is FriendsListInitial) {
          return const FriendsListSkeleton(isMe: true);
        }

        if (state is FriendsListError) {
          return _buildErrorState(context, theme, state.message);
        }

        final friends = (state as FriendsListLoaded).friends;

        if (friends.isEmpty) {
          return _buildEmptyState(theme);
        }

        return Column(
          children: [
            _buildMutualFriendsPlaceholder(),
            Expanded(
              child: CustomPullToRefresh(
                onRefresh: () => context.read<FriendsListCubit>().loadFriends(),
                child: ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: ClampingScrollPhysics(),
                  ),
                  itemCount: friends.length,
                  separatorBuilder: (_, __) => const Gap(10),
                  itemBuilder: (context, i) {
                    final friend = friends[i];
                    return FriendTileWidget(
                      key: ValueKey(friend.friendshipId),
                      friend: friend,
                      isMe: true,
                      onUnfriend:
                          () => context.read<FriendsListCubit>().unfriend(
                            friend.friendshipId,
                          ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
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
              'No friends yet',
              style: theme.textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const Gap(6),
            Text(
              'People you add as friends will show up here.',
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

  Widget _buildErrorState(
    BuildContext context,
    ThemeData theme,
    String message,
  ) {
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
            TextButton(
              onPressed: () => context.read<FriendsListCubit>().loadFriends(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
