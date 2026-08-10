import 'package:flutter/material.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../features/group_chats/models/group_model.dart';

class NewChatGroupTile extends StatelessWidget {
  final GroupModel group;
  final VoidCallback onTap;
  final bool isBlocked;
  const NewChatGroupTile({
    super.key,
    required this.group,
    required this.onTap,
    this.isBlocked = false,
  });

  bool get _hasRealImage =>
      group.avatarUrl != null && group.avatarUrl!.isNotEmpty;

  void _openFullScreenAvatar(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pushNamed(
      AppRoutes.fullScreenImageViewRoute,
      arguments: {
        'url': group.avatarUrl!,
        'tag': 'new_chat_group_avatar_${group.id}',
        'isAsset': false,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tile = ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
      leading: AppAvatar(
        imageUrl: group.avatarUrl,
        size: 48,
        heroTag: 'new_chat_group_avatar_${group.id}',
        onTap: _hasRealImage ? () => _openFullScreenAvatar(context) : null,
      ),
      title: Text(
        group.name,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: const Text(
        'Group',
        style: TextStyle(color: Colors.grey, fontSize: 12),
      ),
    );

    return isBlocked ? Opacity(opacity: 0.5, child: tile) : tile;
  }
}
