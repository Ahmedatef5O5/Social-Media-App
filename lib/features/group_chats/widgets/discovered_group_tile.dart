import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';
import '../models/group_model.dart';
import 'group_square_avatar.dart';

/// Row for a PUBLIC group the viewer has not joined (discovery + search).
/// Shows a Public badge, member count and either a "Requested" pill or a
/// chevron. Tapping opens the group profile (preview / request-to-join).
class DiscoveredGroupTile extends StatelessWidget {
  final GroupModel group;
  final VoidCallback onTap;
  const DiscoveredGroupTile({
    super.key,
    required this.group,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final primary = theme.primaryColor;
    final snippet =
        (group.title?.trim().isNotEmpty == true)
            ? group.title!.trim()
            : group.description?.trim();
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              GroupSquareAvatar(url: group.avatarUrl, size: 54, radius: 16),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            group.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall!.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              letterSpacing: context.ls(0),
                            ),
                          ),
                        ),
                        const Gap(6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.public_rounded,
                                size: 11,
                                color: primary,
                              ),
                              const Gap(3),
                              Text(
                                context.l10n.groupPrivacyPublic,
                                style: TextStyle(
                                  color: primary,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: context.ls(0),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Gap(3),
                    Text(
                      [
                        if (group.membersCount != null)
                          context.l10n.membersCountLabel(group.membersCount!),
                        if (snippet != null && snippet.isNotEmpty) snippet,
                      ].join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: muted,
                        letterSpacing: context.ls(0),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(6),
              if (group.hasPendingJoinRequest)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    context.l10n.groupRequested,
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                Icon(
                  isRtl
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  color: muted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
