import 'package:flutter/material.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/cached_cloudinary_image.dart';
import '../../group_chats/models/group_model.dart';

class GroupSearchResultTile extends StatelessWidget {
  final GroupModel group;
  const GroupSearchResultTile({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    final hasAvatar = group.avatarUrl != null && group.avatarUrl!.isNotEmpty;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: ClipOval(
        child: Container(
          width: 48,
          height: 48,
          color: primary.withValues(alpha: 0.12),
          child:
              hasAvatar
                  ? CachedCloudinaryImage(
                    secureUrl: group.avatarUrl!,
                    fit: BoxFit.cover,
                    isAvatar: true,
                  )
                  : Center(
                    child: Text(
                      group.name.isNotEmpty ? group.name[0].toUpperCase() : 'G',
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
        ),
      ),
      title: Text(
        group.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleSmall!.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        group.title?.isNotEmpty == true ? group.title! : 'Group',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall!.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      onTap:
          () => Navigator.of(
            context,
            rootNavigator: true,
          ).pushNamed(AppRoutes.groupChatRoute, arguments: group),
    );
  }
}
