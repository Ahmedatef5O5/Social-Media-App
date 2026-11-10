import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/helpers/formatted_date.dart';
import '../../../core/themes/app_colors.dart';
import '../../auth/data/models/user_data.dart';
import '../models/social_platform_info.dart';
import 'social_media_preview_card.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

class ProfileDetailsWidgetTab extends StatelessWidget {
  final UserData user;
  final ValueNotifier<double> refreshProgress;
  final ValueNotifier<bool> isRefreshing;
  const ProfileDetailsWidgetTab({
    super.key,
    required this.user,
    required this.refreshProgress,
    required this.isRefreshing,
  });

  @override
  Widget build(BuildContext context) {
    final populatedSocialLinks =
        SocialPlatformInfo.all
            .where(
              (platform) =>
                  (user.socialLinks[platform.key] ?? '').trim().isNotEmpty,
            )
            .toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      padding: const EdgeInsets.all(20),
      children: [
        _buildInfoRow(
          CupertinoIcons.mail,
          context.l10n.email,
          user.email,
          context,
        ),
        const Gap(15),
        _buildInfoRow(
          CupertinoIcons.person_fill,
          context.l10n.fullName,
          user.name,
          context,
        ),
        const Gap(15),
        _buildInfoRow(
          CupertinoIcons.person_circle,
          context.l10n.fieldUsername,
          user.userName,
          context,
        ),
        const Gap(15),
        _buildInfoRow(
          CupertinoIcons.info,
          context.l10n.fieldJobTitle,
          user.title,
          context,
        ),
        const Gap(15),
        _buildInfoRow(
          CupertinoIcons.info,
          context.l10n.fieldBio,
          user.bio,
          context,
        ),
        const Gap(15),
        _buildJoinedRow(context),

        if (populatedSocialLinks.isNotEmpty) ...[
          const Gap(25),
          Row(
            children: [
              Icon(
                Icons.share_rounded,
                size: 18,
                color: Theme.of(context).primaryColor,
              ),
              const Gap(8),
              Text(
                context.l10n.socialMedia,
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall!.copyWith(fontSize: 16),
              ),
            ],
          ),
          const Gap(14),
          for (final platform in populatedSocialLinks)
            SocialMediaPreviewCard(
              platform: platform,
              rawValue: user.socialLinks[platform.key]!.trim(),
            ),
        ],

        const Gap(50),
      ],
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String title,
    String? value,
    BuildContext context,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: AppColors.grey, fontSize: 12),
              ),
              Text(
                (value == null || value.isEmpty)
                    ? context.l10n.noProvidedYet(title)
                    : value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildJoinedRow(BuildContext context) {
    final createdAt = user.createdAt;
    final locale = Localizations.localeOf(context).toString();
    final dateStr =
        createdAt != null
            ? FormattedDate.formatJoinedDate(createdAt, locale: locale)
            : null;
    final durationBadge =
        createdAt != null
            ? FormattedDate.getMembershipDuration(createdAt, locale: locale)
            : null;

    final primaryColor = Theme.of(context).primaryColor;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(CupertinoIcons.calendar, size: 20, color: primaryColor),
        ),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.fieldJoined,
                style: const TextStyle(color: AppColors.grey, fontSize: 12),
              ),
              const Gap(2),
              if (dateStr == null || dateStr.isEmpty)
                Text(
                  context.l10n.noProvidedYet(context.l10n.fieldJoined),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                )
              else
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (durationBadge != null && durationBadge.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.2),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          durationBadge,
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
