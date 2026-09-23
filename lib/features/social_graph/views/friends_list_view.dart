import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/widgets/custom_pull_to_refresh.dart';
import '../../../core/widgets/empty_findings_animation_widget.dart';
import '../cubits/friend_lists_cubit/friends_list_cubit.dart';
import '../widgets/friend_tile_widget.dart';
import '../widgets/friends_list_skeleton.dart';

class FriendsListView extends StatefulWidget {
  final String userId;
  const FriendsListView({super.key, required this.userId});

  @override
  State<FriendsListView> createState() => _FriendsListViewState();
}

class _FriendsListViewState extends State<FriendsListView> {
  final _scrollController = ScrollController();

  static const double _prefetchDistance = 400;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _prefetchDistance) {
      context.read<FriendsListCubit>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = SupabaseProvider.id;
    final isMe = widget.userId == currentUserId;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: InkWell(
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(50),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: theme.primaryColor,
            size: 22,
          ),
        ),
        title: Text(
          'Friends',
          style: theme.textTheme.titleMedium!.copyWith(
            color: theme.primaryColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            fontSize: 20,
          ),
        ),
        actions: [
          BlocBuilder<FriendsListCubit, FriendsListState>(
            buildWhen: (previous, current) {
              final previousTotal =
                  previous is FriendsListLoaded ? previous.total : null;
              final currentTotal =
                  current is FriendsListLoaded ? current.total : null;
              return previousTotal != currentTotal ||
                  (previous is FriendsListLoaded) !=
                      (current is FriendsListLoaded);
            },
            builder: (context, state) {
              if (state is! FriendsListLoaded || state.total == 0) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsetsDirectional.only(end: 16),
                child: _TotalFriendsPill(total: state.total),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<FriendsListCubit, FriendsListState>(
        builder: (context, state) {
          if (state is FriendsListLoading || state is FriendsListInitial) {
            return FriendsListSkeleton(isMe: isMe);
          }

          if (state is FriendsListError) {
            return _buildErrorState(context, theme, state.message);
          }

          final loaded = state as FriendsListLoaded;
          final friends = loaded.friends;

          if (friends.isEmpty) {
            return _buildEmptyState(theme);
          }

          final hasFooter = loaded.isLoadingMore || loaded.loadMoreFailed;

          return CustomPullToRefresh(
            onRefresh:
                () => context.read<FriendsListCubit>().loadFriends(
                  isRefresh: true,
                ),
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              physics: const AlwaysScrollableScrollPhysics(
                parent: ClampingScrollPhysics(),
              ),
              itemCount: friends.length + (hasFooter ? 1 : 0),
              separatorBuilder: (_, __) => const Gap(10),
              itemBuilder: (context, i) {
                if (i >= friends.length) {
                  return loaded.loadMoreFailed
                      ? _LoadMoreRetry(
                        onRetry:
                            () =>
                                context
                                    .read<FriendsListCubit>()
                                    .retryLoadMore(),
                      )
                      : _LoadingMoreFooter(isMe: isMe);
                }

                final friend = friends[i];
                return FriendTileWidget(
                  key: ValueKey(friend.friendshipId),
                  friend: friend,
                  isMe: isMe,
                  onUnfriend:
                      () => context.read<FriendsListCubit>().unfriend(
                        friend.friendshipId,
                      ),
                );
              },
            ),
          );
        },
      ),
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
              width: 160,
              height: 160,
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

class _TotalFriendsPill extends StatelessWidget {
  final int total;
  const _TotalFriendsPill({required this.total});

  static String _format(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: isDark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${_format(total)} ${total == 1 ? 'Friend' : 'Friends'}',
        style: TextStyle(
          color: isDark ? Colors.white : theme.primaryColor,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _LoadingMoreFooter extends StatelessWidget {
  final bool isMe;
  const _LoadingMoreFooter({required this.isMe});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        FriendTileSkeleton(isMe: isMe),
        const Gap(10),
        FriendTileSkeleton(isMe: isMe),
        const Gap(14),
        Text(
          'Loading more...',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const Gap(8),
      ],
    );
  }
}

/// Shown when a "load more" request failed; tapping retries it.
class _LoadMoreRetry extends StatelessWidget {
  final VoidCallback onRetry;
  const _LoadMoreRetry({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: TextButton.icon(
          onPressed: onRetry,
          icon: Icon(
            Icons.refresh_rounded,
            size: 18,
            color: theme.primaryColor,
          ),
          label: Text(
            "Couldn't load more · Tap to retry",
            style: TextStyle(
              color: theme.primaryColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
