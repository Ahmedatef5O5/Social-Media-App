import 'package:flutter/material.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/themes/app_colors.dart';
import '../../auth/data/models/user_data.dart';
import '../cubits/profile_cubit/profile_cubit.dart';
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
    return Transform.translate(
      offset: const Offset(0, -30),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                  if (user.userName != null && user.userName!.isNotEmpty) ...[
                    Text(
                      "@${user.userName?.toLowerCase().replaceAll(' ', '_')}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.grey, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(
              width: 174,
              child: FriendsCountBadge(
                isMe: isMe,
                friendsCount: state.friendsCount,
                mutualFriendsCount: state.mutualFriendsCount,
                onTap: () {
                  Navigator.of(context, rootNavigator: true).pushNamed(
                    AppRoutes.friendsListViewRoute,
                    arguments: user.id,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
