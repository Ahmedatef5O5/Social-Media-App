import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/router/app_routes.dart';
import '../../auth/data/models/user_data.dart';
import '../../social_graph/models/friendship_status.dart';
import '../cubits/profile_cubit/profile_cubit.dart';
import '../utils/profile_ui_tokens.dart';
import 'friends_count_badge.dart';

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

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ProfileUiTokens.screenPadding,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    user.name,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                      color: tokens.onSurface,
                    ),
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
                if (user.userName != null && user.userName!.isNotEmpty) ...[
                  const Gap(2),
                  Text(
                    "@${user.userName?.toLowerCase().replaceAll(' ', '_')}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tokens.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (showFriendsBadge) ...[
            const Gap(12),
            FriendsCountBadge(
              isMe: isMe,
              friendsCount: state.friendsCount,
              mutualFriendsCount: state.mutualFriendsCount,
              mutualPreviews: state.mutuals.friends,
              onTap: () {
                Navigator.of(
                  context,
                  rootNavigator: true,
                ).pushNamed(AppRoutes.friendsListViewRoute, arguments: user.id);
              },
            ),
          ],
        ],
      ),
    );
  }
}
