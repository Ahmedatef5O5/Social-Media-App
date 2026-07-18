import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/app_avatar.dart';
import '../models/friend_list_item_model.dart';
import 'unfriend_confirmation_dialog.dart';

class FriendTileWidget extends StatelessWidget {
  final FriendListItemModel friend;
  final bool isMe;
  final VoidCallback? onUnfriend;

  const FriendTileWidget({
    super.key,
    required this.friend,
    required this.isMe,
    this.onUnfriend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = friend.user;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap:
          () => Navigator.of(
            context,
            rootNavigator: true,
          ).pushNamed(AppRoutes.profileViewRoute, arguments: user.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.12),
          ),
        ),
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
              child: AppAvatar(imageUrl: user.imageUrl, size: 48),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge!.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 15.5,
                    ),
                  ),
                  if ((user.userName ?? '').isNotEmpty) ...[
                    const Gap(3),
                    Text(
                      '@${user.userName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: AppColors.grey4),
                    ),
                  ],
                ],
              ),
            ),
            if (isMe) ...[const Gap(8), _buildMoreButton(context, theme)],
          ],
        ),
      ),
    );
  }

  Widget _buildMoreButton(BuildContext context, ThemeData theme) {
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => _showOptionsSheet(context),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            Icons.more_horiz_rounded,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  void _showOptionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Gap(10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Gap(8),
              ListTile(
                leading: const Icon(
                  Icons.person_remove_rounded,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  'Unfriend',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final confirmed = await showUnfriendConfirmationDialog(
                    context,
                    friendName: friend.user.name,
                  );
                  if (confirmed == true) onUnfriend?.call();
                },
              ),
              const Gap(8),
            ],
          ),
        );
      },
    );
  }
}
