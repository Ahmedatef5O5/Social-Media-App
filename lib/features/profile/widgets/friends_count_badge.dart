import 'package:flutter/material.dart';
import '../models/profile_mutuals_model.dart';
import '../utils/profile_ui_tokens.dart';
import 'profile_avatar_stack.dart';

class FriendsCountBadge extends StatelessWidget {
  final bool isMe;
  final int friendsCount;
  final int mutualFriendsCount;
  final List<ProfileMutualFriend> mutualPreviews;
  final VoidCallback onTap;

  const FriendsCountBadge({
    super.key,
    required this.isMe,
    required this.friendsCount,
    required this.mutualFriendsCount,
    required this.onTap,
    this.mutualPreviews = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (friendsCount == 0) return const SizedBox.shrink();

    final tokens = ProfileUiTokens.of(context);
    final showMutual = !isMe && mutualFriendsCount > 0;
    final avatarUrls =
        mutualPreviews.take(2).map((friend) => friend.imageUrl).toList();

    return Material(
      color: tokens.surfaceVariant,
      borderRadius: BorderRadius.circular(ProfileUiTokens.buttonRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(ProfileUiTokens.buttonRadius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showMutual && avatarUrls.isNotEmpty) ...[
                ProfileAvatarStack(
                  imageUrls: avatarUrls,
                  size: 20,
                  overlap: 8,
                  ringWidth: 1.5,
                  ringColor: tokens.surfaceVariant,
                ),
                const SizedBox(width: 8),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$friendsCount ${friendsCount == 1 ? 'Friend' : 'Friends'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: tokens.onSurface,
                      height: 1.2,
                    ),
                  ),
                  if (showMutual) ...[
                    const SizedBox(height: 2),
                    Text(
                      '$mutualFriendsCount Mutual',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: tokens.onSurfaceVariant,
                        height: 1.2,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
