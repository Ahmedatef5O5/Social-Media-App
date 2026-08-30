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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        context.read<FriendsListCubit>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
      ),
      body: BlocBuilder<FriendsListCubit, FriendsListState>(
        builder: (context, state) {
          if (state is FriendsListLoading || state is FriendsListInitial) {
            return FriendsListSkeleton(isMe: isMe);
          }

          if (state is FriendsListError) {
            return _buildErrorState(context, theme, state.message);
          }

          final friends = (state as FriendsListLoaded).friends;

          if (friends.isEmpty) {
            return _buildEmptyState(theme);
          }

          return CustomPullToRefresh(
            onRefresh: () => context.read<FriendsListCubit>().loadFriends(),
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
