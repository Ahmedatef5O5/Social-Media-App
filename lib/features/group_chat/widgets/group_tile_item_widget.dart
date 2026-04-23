import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../core/helpers/formatted_date.dart';
import '../../../core/router/app_routes.dart';
import '../models/group_model.dart';

class GroupTileItem extends StatelessWidget {
  final GroupModel group;
  const GroupTileItem({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hasAvatar = group.avatarUrl != null && group.avatarUrl!.isNotEmpty;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: primary.withValues(alpha: 0.12),
        backgroundImage:
            hasAvatar ? CachedNetworkImageProvider(group.avatarUrl!) : null,
        child:
            hasAvatar
                ? null
                : Text(
                  group.name.isNotEmpty ? group.name[0].toUpperCase() : 'G',
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
      ),
      title: Text(
        group.name,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle:
          group.lastMessage != null
              ? Text(
                _buildLastMessagePreview(group),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 13,
                ),
              )
              : Text(
                'Tap to open group chat',
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 13,
                ),
              ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (group.lastMessageAt != null)
            Text(
              FormattedDate.getMessageTime(group.lastMessageAt!),
              style: TextStyle(
                color:
                    group.unreadCount > 0
                        ? primary
                        : (isDark ? Colors.white38 : Colors.black38),
                fontSize: 11,
              ),
            ),
          if (group.unreadCount > 0) ...[
            const Gap(4),
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
              child: Text(
                group.unreadCount > 99 ? '99+' : '${group.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      onTap: () {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushNamed(AppRoutes.groupChatRoute, arguments: group);
      },
    );
  }

  String _buildLastMessagePreview(GroupModel group) {
    final type = group.lastMessageType ?? 'text';
    final text = group.lastMessage ?? '';
    switch (type) {
      case 'image':
        return '📷 Photo';
      case 'video':
        return '🎬 Video';
      case 'voice':
        return '🎤 Voice message';
      case 'call':
        return '📞 Call';
      default:
        return text;
    }
  }
}
