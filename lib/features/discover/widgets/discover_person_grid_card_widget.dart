import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../cubits/discover_people_cubit.dart';
import 'discover_grid_action_button.dart';

class DiscoverPersonGridCardWidget extends StatefulWidget {
  final DiscoverPersonModel personData;
  final String? highlightQuery;
  final VoidCallback? onDismiss;

  const DiscoverPersonGridCardWidget({
    super.key,
    required this.personData,
    this.highlightQuery,
    this.onDismiss,
  });

  @override
  State<DiscoverPersonGridCardWidget> createState() =>
      _DiscoverPersonGridCardWidgetState();
}

class _DiscoverPersonGridCardWidgetState
    extends State<DiscoverPersonGridCardWidget> {
  bool _isDismissing = false;

  void _handleDismissTap() {
    if (_isDismissing) return;
    HapticFeedback.lightImpact();
    setState(() => _isDismissing = true);
  }

  Future<void> _handleFriendAction(BuildContext context) async {
    try {
      final cubit = context.read<DiscoverPeopleCubit>();
      switch (widget.personData.friendshipStatus) {
        case FriendshipStatus.none:
          await cubit.sendFriendRequest(widget.personData.user.id);
          break;
        case FriendshipStatus.pendingSent:
          if (widget.personData.friendshipId != null) {
            await cubit.cancelFriendRequest(
              widget.personData.user.id,
              widget.personData.friendshipId!,
            );
          }
          break;
        case FriendshipStatus.pendingReceived:
          await cubit.acceptFriendRequest(widget.personData.user.id);
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
        widget.personData.user.id,
        isCurrentlyFollowing: widget.personData.isFollowing,
      );
    } catch (_) {
      AppToast.error('Something went wrong. Please try again.');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final person = widget.personData;
    final userData = person.user;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      opacity: _isDismissing ? 0 : 1,
      onEnd: () {
        if (_isDismissing) widget.onDismiss?.call();
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        scale: _isDismissing ? 0.82 : 1,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(
                alpha: isDark ? 0.3 : 0.6,
              ),
              width: 1,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap:
                    () => Navigator.of(context, rootNavigator: true).pushNamed(
                      AppRoutes.profileViewRoute,
                      arguments: userData.id,
                    ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.outlineVariant,
                            width: 2,
                          ),
                        ),
                        child: PresenceAvatarWidget(
                          userId: userData.id,
                          avatarSize: 64,
                          showDot: true,
                          showBorder: false,
                          child: AppAvatar(
                            imageUrl: userData.imageUrl,
                            size: 64,
                            onTap:
                                () => showDialog(
                                  context: context,
                                  builder:
                                      (context) => UserPreviewDialog(
                                        user: ChatUserModel.fromEntity(
                                          userData,
                                        ),
                                      ),
                                ),
                          ),
                        ),
                      ),
                      const Gap(8),
                      _buildText(
                        text: userData.name,
                        query: widget.highlightQuery,
                        baseStyle: theme.textTheme.labelLarge!.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.5,
                          color: colorScheme.onSurface,
                        ),
                        highlightColor: theme.primaryColor,
                      ),
                      if ((userData.userName ?? '').isNotEmpty) ...[
                        const Gap(2),
                        _buildText(
                          text: '@${userData.userName!.replaceAll('@', '')}',
                          query: widget.highlightQuery,
                          baseStyle: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w400,
                            color: AppColors.grey4,
                          ),
                          highlightColor: theme.primaryColor,
                        ),
                      ],
                      if (person.followsMe) ...[
                        const Gap(5),
                        _FollowsYouBadge(theme: theme),
                      ],
                      if (person.mutualFriendsCount > 0) ...[
                        const Gap(6),
                        _MutualAvatarsStack(
                          previews: person.mutualFriendsPreview,
                          totalMutualCount: person.mutualFriendsCount,
                        ),
                      ] else if (person.totalFriendsCount > 0) ...[
                        const Gap(6),
                        _MetaLine(
                          icon: Icons.people_alt_rounded,
                          label:
                              '${person.totalFriendsCount} '
                              '${person.totalFriendsCount == 1 ? 'friend' : 'friends'}',
                        ),
                      ],
                      if (person.mutualGroupsCount > 0) ...[
                        const Gap(3),
                        _MetaLine(
                          icon: Icons.groups_rounded,
                          label:
                              '${person.mutualGroupsCount} mutual '
                              '${person.mutualGroupsCount == 1 ? 'group' : 'groups'}',
                        ),
                      ],
                      const Gap(12),
                      SizedBox(
                        width: double.infinity,
                        child: _buildFriendAction(context, theme),
                      ),
                      const Gap(6),
                      SizedBox(
                        width: double.infinity,
                        child: DiscoverGridActionButton(
                          isActive: person.isFollowing,
                          idleLabel: 'Follow',
                          activeLabel: 'Following',
                          idleIcon: Icons.person_add_rounded,
                          activeIcon: Icons.check_rounded,
                          onPressed: () => _handleFollowAction(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.onDismiss != null)
                Positioned(
                  top: 6,
                  right: 6,
                  child: _DismissButton(onTap: _handleDismissTap),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFriendAction(BuildContext context, ThemeData theme) {
    final person = widget.personData;
    switch (person.friendshipStatus) {
      case FriendshipStatus.none:
        return DiscoverGridActionButton(
          isActive: false,
          idleLabel: 'Add Friend',
          activeLabel: 'Requested',
          idleIcon: Icons.person_add_alt_1_rounded,
          activeIcon: Icons.hourglass_top_rounded,
          onPressed: () => _handleFriendAction(context),
        );
      case FriendshipStatus.pendingSent:
        return DiscoverGridActionButton(
          isActive: true,
          idleLabel: 'Add Friend',
          activeLabel: 'Requested',
          idleIcon: Icons.person_add_alt_1_rounded,
          activeIcon: Icons.hourglass_top_rounded,
          onPressed: () => _handleFriendAction(context),
        );
      case FriendshipStatus.pendingReceived:
        return _GridStaticChip(
          theme: theme,
          label: 'Accept',
          icon: Icons.person_add_alt_1_rounded,
          filled: true,
          onTap: () => _handleFriendAction(context),
        );
      case FriendshipStatus.accepted:
        return _GridStaticChip(
          theme: theme,
          label: 'Friends',
          icon: Icons.people_alt_rounded,
          filled: false,
          onTap: null,
        );
    }
  }

  Widget _buildText({
    required String text,
    required String? query,
    required TextStyle baseStyle,
    required Color highlightColor,
  }) {
    if (query == null || query.trim().isEmpty) {
      return Text(
        text,
        maxLines: 1,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: baseStyle,
      );
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.trim().toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (start < text.length) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(start), style: baseStyle));
        break;
      }
      if (index > start) {
        spans.add(
          TextSpan(text: text.substring(start, index), style: baseStyle),
        );
      }
      spans.add(
        TextSpan(
          text: text.substring(index, index + lowerQuery.length),
          style: baseStyle.copyWith(
            color: highlightColor,
            fontWeight: FontWeight.w700,
            backgroundColor: highlightColor.withValues(alpha: 0.12),
          ),
        ),
      );
      start = index + lowerQuery.length;
    }

    return Text.rich(
      TextSpan(children: spans),
      maxLines: 1,
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _DismissButton extends StatelessWidget {
  final VoidCallback onTap;
  const _DismissButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 22,
          height: 22,
          child: Icon(
            Icons.close_rounded,
            size: 13,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

class _FollowsYouBadge extends StatelessWidget {
  final ThemeData theme;
  const _FollowsYouBadge({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 7, color: theme.primaryColor),
          const SizedBox(width: 2),
          Text(
            'Follows you',
            style: TextStyle(
              fontSize: 7,
              fontWeight: FontWeight.w600,
              color: theme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _MutualAvatarsStack extends StatelessWidget {
  final List<MutualFriendPreviewModel> previews;
  final int totalMutualCount;

  const _MutualAvatarsStack({
    required this.previews,
    required this.totalMutualCount,
  });

  @override
  Widget build(BuildContext context) {
    if (previews.isEmpty) {
      return _MetaLine(
        icon: Icons.people_alt_rounded,
        label:
            '$totalMutualCount mutual '
            '${totalMutualCount == 1 ? 'friend' : 'friends'}',
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 16,
          width: 16 + (previews.length - 1) * 10.0,
          child: Stack(
            children: [
              for (var i = 0; i < previews.length; i++)
                Positioned(
                  left: i * 10.0,
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.surface,
                    ),
                    child: AppAvatar(imageUrl: previews[i].imageUrl, size: 14),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 5),
        Text(
          '$totalMutualCount mutual',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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

class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaLine({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: AppColors.grey4),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.grey4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _GridStaticChip extends StatelessWidget {
  final ThemeData theme;
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback? onTap;

  const _GridStaticChip({
    required this.theme,
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    final fg = filled ? Colors.white : colorScheme.onSurfaceVariant;
    return SizedBox(
      height: 36,
      width: double.infinity,
      child: Material(
        color: filled ? theme.primaryColor : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border:
                  filled
                      ? null
                      : Border.all(color: colorScheme.outlineVariant, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: fg),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
