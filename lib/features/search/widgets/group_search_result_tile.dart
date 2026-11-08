import 'package:flutter/material.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/cached_cloudinary_image.dart';
import '../../group_chats/helpers/group_navigation.dart';
import '../../group_chats/helpers/group_profile_navigation.dart';
import '../../group_chats/models/group_model.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

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
                  : Image.asset(AppImages.defaultGroupImg, fit: BoxFit.cover),
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
      subtitle: Row(
        children: [
          if (!group.isMember && group.isPublic) ...[
            _DiscoverBadge(pending: group.hasPendingJoinRequest),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              [
                if (group.membersCount != null)
                  context.l10n.membersCountLabel(group.membersCount!),
                group.title?.isNotEmpty == true
                    ? group.title!
                    : context.l10n.group,
              ].join(' • '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall!.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
      onTap:
          () =>
              !group.isMember
                  ? openGroupProfile(
                    context,
                    groupId: group.id,
                    group: group,
                  ) // non-member: preview + request to join
                  : openGroupChat(
                    group.id,
                    () => Navigator.of(
                      context,
                      rootNavigator: true,
                    ).pushNamed(AppRoutes.groupChatRoute, arguments: group),
                  ),
    );
  }
}

class _DiscoverBadge extends StatelessWidget {
  final bool pending;
  const _DiscoverBadge({required this.pending});

  @override
  Widget build(BuildContext context) {
    final color = pending ? Colors.orange : Theme.of(context).primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            pending ? Icons.hourglass_top_rounded : Icons.public_rounded,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            pending
                ? context.l10n.groupRequested
                : context.l10n.groupPublicDiscoverBadge,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
