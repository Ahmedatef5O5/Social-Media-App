import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/features/group_chat/helpers/group_preview_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/helpers/formatted_date.dart';
import '../../../core/router/app_routes.dart';
import '../helpers/last_message_group_preview.dart';
import '../models/group_model.dart';

class GroupTileItem extends StatelessWidget {
  final GroupModel group;
  const GroupTileItem({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final primary = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hasAvatar = group.avatarUrl != null && group.avatarUrl!.isNotEmpty;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: GestureDetector(
        onTap:
            hasAvatar
                ? () {
                  showDialog(
                    context: context,
                    barrierColor: Colors.black54,
                    builder: (_) => GroupPreviewDialog(group: group),
                  );
                }
                : null,
        child: ClipOval(
          child: Container(
            width: 52,
            height: 52,
            color: primary.withValues(alpha: 0.12),
            child:
                hasAvatar
                    ? CachedNetworkImage(
                      imageUrl: group.avatarUrl!,
                      fit: BoxFit.cover,
                      memCacheWidth: 300,
                      memCacheHeight: 300,
                    )
                    : Center(
                      child: Text(
                        group.name.isNotEmpty
                            ? group.name[0].toUpperCase()
                            : 'G',
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
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
                buildGroupLastMessagePreview(
                  group: group,
                  currentUserId: currentUserId ?? '',
                ),
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
}
