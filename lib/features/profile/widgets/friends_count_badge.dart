import 'package:flutter/material.dart';

import '../../../core/themes/app_colors.dart';

class FriendsCountBadge extends StatelessWidget {
  final bool isMe;
  final int friendsCount;
  final int mutualFriendsCount;
  final VoidCallback onTap;

  const FriendsCountBadge({
    super.key,
    required this.isMe,
    required this.friendsCount,
    required this.mutualFriendsCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final showMutual = !isMe && mutualFriendsCount > 0;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$friendsCount ${friendsCount == 1 ? 'Friend' : 'Friends'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            if (showMutual) ...[
              const SizedBox(height: 2),
              Text(
                '$mutualFriendsCount Mutual',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.5, color: AppColors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
