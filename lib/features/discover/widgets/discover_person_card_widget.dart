import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import '../../../core/presence/widgets/presence_avatar_widget.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/toast/app_toast.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../profile/widgets/user_preview_dialog.dart';
import '../../single_chats/models/chat_user_model.dart';
import '../../social_graph/models/discover_person_model.dart';
import '../../social_graph/models/friendship_status.dart';
import '../../social_graph/widgets/animated_action_button.dart';
import '../cubits/discover_people_cubit.dart';

class DiscoverPersonCardWidget extends StatelessWidget {
  final DiscoverPersonModel personData;
  final List<BoxShadow>? boxShadow;
  final bool isCompact;

  const DiscoverPersonCardWidget({
    super.key,
    required this.personData,
    this.boxShadow,
    this.isCompact = false,
  });

  Future<void> _handleFriendAction(BuildContext context) async {
    try {
      final cubit = context.read<DiscoverPeopleCubit>();
      switch (personData.friendshipStatus) {
        case FriendshipStatus.none:
          await cubit.sendFriendRequest(personData.user.id);
          break;
        case FriendshipStatus.pendingSent:
          if (personData.friendshipId != null) {
            await cubit.cancelFriendRequest(
              personData.user.id,
              personData.friendshipId!,
            );
          }
          break;
        case FriendshipStatus.pendingReceived:
          await cubit.acceptFriendRequest(personData.user.id);
          break;
        case FriendshipStatus.accepted:
          break;
      }
    } catch (_) {
      AppToast.error('Something went wrong. Please try again.');
      rethrow;
    }
  }

  Future<void> _handleFollowAction(BuildContext context) async {
    try {
      await context.read<DiscoverPeopleCubit>().toggleFollow(
        personData.user.id,
        isCurrentlyFollowing: personData.isFollowing,
      );
    } catch (_) {
      AppToast.error('Something went wrong. Please try again.');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userData = personData.user;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(
            alpha: isDark ? 0.3 : 0.6,
          ),
          width: 1,
        ),
        boxShadow:
            boxShadow ??
            [
              BoxShadow(
                color:
                    isDark
                        ? Colors.black.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap:
                () => Navigator.of(
                  context,
                  rootNavigator: true,
                ).pushNamed(AppRoutes.profileViewRoute, arguments: userData.id),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar with Presence
                Container(
                  padding: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.primaryColor.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: PresenceAvatarWidget(
                    userId: userData.id,
                    avatarSize: isCompact ? 44 : 50,
                    showDot: true,
                    showBorder: false,
                    child: AppAvatar(
                      imageUrl: userData.imageUrl,
                      size: isCompact ? 44 : 50,
                      onTap:
                          () => showDialog(
                            context: context,
                            builder:
                                (context) => UserPreviewDialog(
                                  user: ChatUserModel.fromEntity(userData),
                                ),
                          ),
                    ),
                  ),
                ),
                const Gap(10),

                // Name & Metadata Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              userData.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelLarge!.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: isCompact ? 14.5 : 16.0,
                              ),
                            ),
                          ),
                          if (!isCompact && personData.followsMe) ...[
                            const Gap(6),
                            _FollowsYouBadge(theme: theme),
                          ],
                        ],
                      ),
                      const Gap(2),
                      Row(
                        children: [
                          if ((userData.userName ?? '').isNotEmpty)
                            Flexible(
                              child: Text(
                                '@${userData.userName!.replaceAll('@', '')}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelMedium!.copyWith(
                                  fontWeight: FontWeight.w400,
                                  fontSize: isCompact ? 12 : 13,
                                  color: AppColors.grey4,
                                ),
                              ),
                            ),
                          if (isCompact && personData.followsMe) ...[
                            const Gap(6),
                            _FollowsYouBadge(theme: theme, isMini: true),
                          ],
                        ],
                      ),
                      if (isCompact) ...[
                        const Gap(3),
                        _buildCompactSocialProof(theme),
                      ],
                    ],
                  ),
                ),

                // Right Column (Only in Full-Width Mode)
                if (!isCompact) ...[
                  const Gap(8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _DiscoverFriendCounts(
                        totalFriendsCount: personData.totalFriendsCount,
                        mutualFriendsCount: personData.mutualFriendsCount,
                        onTap: () {
                          Navigator.of(context, rootNavigator: true).pushNamed(
                            AppRoutes.friendsListViewRoute,
                            arguments: userData.id,
                          );
                        },
                      ),
                      if (personData.mutualGroupsCount > 0) ...[
                        const Gap(4),
                        _MutualGroupsLabel(count: personData.mutualGroupsCount),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          Gap(isCompact ? 10 : 13),

          // Action Buttons Row
          Row(
            children: [
              Expanded(child: _buildFriendAction(context, theme)),
              const Gap(8),
              Expanded(
                child: AnimatedActionButton(
                  height: isCompact ? 34 : 38,
                  isActive: personData.isFollowing,
                  idleLabel: 'Follow',
                  activeLabel: 'Following',
                  idleIcon: Icons.person_add_rounded,
                  activeIcon: Icons.check_rounded,
                  onPressed: () => _handleFollowAction(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSocialProof(ThemeData theme) {
    if (personData.mutualFriendsCount > 0) {
      return Text(
        '${personData.mutualFriendsCount} mutual friends',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: theme.primaryColor,
        ),
      );
    } else if (personData.totalFriendsCount > 0) {
      return Text(
        '${personData.totalFriendsCount} friends',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: AppColors.grey4,
        ),
      );
    } else if (personData.mutualGroupsCount > 0) {
      return Text(
        '${personData.mutualGroupsCount} mutual groups',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: AppColors.grey4,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildFriendAction(BuildContext context, ThemeData theme) {
    final double buttonHeight = isCompact ? 34 : 38;
    switch (personData.friendshipStatus) {
      case FriendshipStatus.none:
        return AnimatedActionButton(
          height: buttonHeight,
          isActive: false,
          idleLabel: 'Add Friend',
          activeLabel: 'Requested',
          idleIcon: Icons.person_add_alt_1_rounded,
          activeIcon: Icons.hourglass_top_rounded,
          onPressed: () => _handleFriendAction(context),
        );
      case FriendshipStatus.pendingSent:
        return AnimatedActionButton(
          height: buttonHeight,
          isActive: true,
          idleLabel: 'Add Friend',
          activeLabel: 'Requested',
          idleIcon: Icons.person_add_alt_1_rounded,
          activeIcon: Icons.hourglass_top_rounded,
          onPressed: () => _handleFriendAction(context),
        );
      case FriendshipStatus.pendingReceived:
        return _StaticChip(
          height: buttonHeight,
          theme: theme,
          label: 'Accept',
          icon: Icons.person_add_alt_1_rounded,
          onTap: () => _handleFriendAction(context),
        );
      case FriendshipStatus.accepted:
        return _StaticChip(
          height: buttonHeight,
          theme: theme,
          label: 'Friends',
          icon: Icons.people_alt_rounded,
          onTap: null,
        );
    }
  }
}

class _FollowsYouBadge extends StatelessWidget {
  final ThemeData theme;
  final bool isMini;
  const _FollowsYouBadge({required this.theme, this.isMini = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMini ? 4 : 5, vertical: 2),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: isMini ? 6 : 7,
            color: theme.primaryColor,
          ),
          const SizedBox(width: 2),
          Text(
            'Follows you',
            style: TextStyle(
              fontSize: isMini ? 6 : 7,
              fontWeight: FontWeight.w600,
              color: theme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _StaticChip extends StatelessWidget {
  final ThemeData theme;
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final double height;

  const _StaticChip({
    required this.theme,
    required this.label,
    required this.icon,
    required this.onTap,
    this.height = 38,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(height / 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(height / 2),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscoverFriendCounts extends StatelessWidget {
  final int totalFriendsCount;
  final int mutualFriendsCount;
  final VoidCallback onTap;

  const _DiscoverFriendCounts({
    required this.totalFriendsCount,
    required this.mutualFriendsCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (totalFriendsCount == 0) return const SizedBox.shrink();
    final showMutual = mutualFriendsCount > 0;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$totalFriendsCount ${totalFriendsCount == 1 ? 'Friend' : 'Friends'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (showMutual) ...[
              const SizedBox(height: 2),
              Text(
                '$mutualFriendsCount Mutual',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.grey4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MutualGroupsLabel extends StatelessWidget {
  final int count;
  const _MutualGroupsLabel({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.groups_rounded, size: 12, color: AppColors.grey4),
        const SizedBox(width: 3),
        Text(
          '$count mutual ${count == 1 ? 'group' : 'groups'}',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.grey4,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
