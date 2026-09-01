import 'package:flutter/material.dart';
import '../../../core/constants/app_images.dart';
import '../models/blocked_user_item_model.dart';

class BlockedUserTile extends StatelessWidget {
  final BlockedUserItemModel item;
  final VoidCallback onTap;
  final VoidCallback onUnblock;

  const BlockedUserTile({
    super.key,
    required this.item,
    required this.onTap,
    required this.onUnblock,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = item.user;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Opacity(
                opacity: 0.55,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: theme.primaryColor.withValues(
                        alpha: 0.1,
                      ),
                      backgroundImage:
                          (user.imageUrl != null && user.imageUrl!.isNotEmpty)
                              ? NetworkImage(user.imageUrl!)
                              : const AssetImage(AppImages.defaultUserImg)
                                  as ImageProvider,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Blocked',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.red.shade400,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onUnblock,
              style: TextButton.styleFrom(foregroundColor: theme.primaryColor),
              child: const Text('Unblock'),
            ),
          ],
        ),
      ),
    );
  }
}
