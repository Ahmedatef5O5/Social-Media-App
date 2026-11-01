import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import '../../../core/router/app_routes.dart';
import '../../auth/data/models/user_data.dart';
import '../../group_chats/cubits/group_list_cubit/group_list_cubit.dart';
import '../../social_graph/models/friendship_status.dart';
import '../cubits/profile_cubit/profile_cubit.dart';
import '../utils/profile_ui_tokens.dart';
import 'friends_count_badge.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

class ProfileHeaderUserInfoSection extends StatelessWidget {
  final UserData user;
  final bool isMe;
  final ProfileLoaded state;

  const ProfileHeaderUserInfoSection({
    super.key,
    required this.user,
    required this.isMe,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = ProfileUiTokens.of(context);
    final showFriendsBadge =
        state.friendsCount > 0 &&
        (isMe || state.friendshipStatus == FriendshipStatus.accepted);

    final currentDirection = Directionality.of(context);

    final groupListState = isMe ? context.watch<GroupListCubit>().state : null;
    final myGroupsCount =
        isMe
            ? (groupListState is GroupListLoaded
                ? groupListState.groups
                    .where((g) => g.isMember && !g.isBlocked)
                    .length
                : context
                    .read<GroupListCubit>()
                    .cachedGroupsChats
                    .where((g) => g.isMember && !g.isBlocked)
                    .length)
            : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ProfileUiTokens.screenPadding,
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      user.name,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        letterSpacing: context.ls(-0.3),
                        color: tokens.onSurface,
                      ),
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                  if (user.userName != null && user.userName!.isNotEmpty) ...[
                    const Gap(2),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "@${user.userName?.toLowerCase().replaceAll(' ', '_')}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: tokens.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showFriendsBadge) ...[
              const Gap(8),
              Directionality(
                textDirection: currentDirection,
                child: FriendsCountBadge(
                  isMe: isMe,
                  friendsCount: state.friendsCount,
                  mutualFriendsCount: state.mutualFriendsCount,
                  mutualPreviews: state.mutuals.friends,
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).pushNamed(
                      AppRoutes.friendsListViewRoute,
                      arguments: user.id,
                    );
                  },
                ),
              ),
            ],
            if (isMe) ...[
              const Gap(8),
              Directionality(
                textDirection: currentDirection,
                child: Material(
                  color: tokens.surfaceVariant,
                  borderRadius: BorderRadius.circular(
                    ProfileUiTokens.buttonRadius,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(
                      ProfileUiTokens.buttonRadius,
                    ),
                    onTap: () {
                      Navigator.of(
                        context,
                        rootNavigator: true,
                      ).pushNamed(AppRoutes.yourGroupsRoute);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$myGroupsCount',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: tokens.onSurface,
                              height: 1.2,
                            ),
                          ),
                          const Gap(6),
                          Icon(
                            Icons.groups_rounded,
                            size: 18,
                            color: tokens.onSurface,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
