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
import '../cubit/discover_people_cubit.dart';

class DiscoverPersonCardWidget extends StatelessWidget {
  final DiscoverPersonModel personData;
  const DiscoverPersonCardWidget({super.key, required this.personData});

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

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color:
                theme.brightness == Brightness.dark
                    ? Colors.black.withValues(alpha: 0.35)
                    : Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
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
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.primaryColor.withValues(alpha: 0.15),
                      width: 2,
                    ),
                  ),
                  child: PresenceAvatarWidget(
                    userId: userData.id,
                    avatarSize: 52,
                    showDot: true,
                    showBorder: false,
                    child: AppAvatar(
                      imageUrl: userData.imageUrl,
                      size: 52,
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
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userData.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge!.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 16.5,
                        ),
                      ),
                      const Gap(4),
                      Row(
                        children: [
                          if ((userData.userName ?? '').isNotEmpty)
                            Flexible(
                              child: Text(
                                userData.userName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelMedium!.copyWith(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 13,
                                  color: AppColors.grey4,
                                ),
                              ),
                            ),
                          if ((userData.userName ?? '').isNotEmpty &&
                              personData.followsMe)
                            const Gap(6),
                          if (personData.followsMe)
                            _FollowsYouBadge(theme: theme),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Gap(14),
          Row(
            children: [
              Expanded(child: _buildFriendAction(context, theme)),
              const Gap(10),
              Expanded(
                child: AnimatedActionButton(
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

  Widget _buildFriendAction(BuildContext context, ThemeData theme) {
    switch (personData.friendshipStatus) {
      case FriendshipStatus.none:
        return AnimatedActionButton(
          isActive: false,
          idleLabel: 'Add Friend',
          activeLabel: 'Requested',
          idleIcon: Icons.person_add_alt_1_rounded,
          activeIcon: Icons.hourglass_top_rounded,
          onPressed: () => _handleFriendAction(context),
        );
      case FriendshipStatus.pendingSent:
        return AnimatedActionButton(
          isActive: true,
          idleLabel: 'Add Friend',
          activeLabel: 'Requested',
          idleIcon: Icons.person_add_alt_1_rounded,
          activeIcon: Icons.hourglass_top_rounded,
          onPressed: () => _handleFriendAction(context),
        );
      case FriendshipStatus.pendingReceived:
        return _StaticChip(
          theme: theme,
          label: 'Respond',
          icon: Icons.mark_email_unread_rounded,
          onTap:
              () => AppToast.info(
                'Check your notifications to respond to this request',
              ),
        );
      case FriendshipStatus.accepted:
        return _StaticChip(
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
  const _FollowsYouBadge({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 11, color: theme.primaryColor),
          const SizedBox(width: 4),
          Text(
            'Follows you',
            style: TextStyle(
              fontSize: 11,
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

  const _StaticChip({
    required this.theme,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(19),
        child: InkWell(
          borderRadius: BorderRadius.circular(19),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
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
