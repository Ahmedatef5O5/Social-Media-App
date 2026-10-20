import 'package:flutter/material.dart';
import '../models/content_privacy.dart';
import 'privacy_option_card.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

Future<ContentPrivacy?> showPrivacySelectorSheet(
  BuildContext context, {
  required ContentPrivacy currentPrivacy,
  bool isStory = false,
  bool isPack = false,
}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return showModalBottomSheet<ContentPrivacy>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? theme.scaffoldBackgroundColor : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30,
              spreadRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        padding: const EdgeInsets.only(bottom: 32, top: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              isPack ? context.l10n.whoCanSeeThis : context.l10n.whoCanSeeThis2,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: context.ls(0.2),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isPack
                  ? context.l10n.chooseYourAudienceFor
                  : (isStory
                      ? context.l10n.chooseYourAudienceFor2
                      : context.l10n.chooseYourAudienceFor3),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),

            PrivacyOptionCard(
              value: ContentPrivacy.public,
              currentValue: currentPrivacy,
              title: context.l10n.public,
              subtitle: context.l10n.anyoneOnTheApp,
              icon: Icons.public_rounded,
            ),
            PrivacyOptionCard(
              value: ContentPrivacy.friends,
              currentValue: currentPrivacy,
              title: context.l10n.friends,
              subtitle: context.l10n.onlyYourFriendsCan,
              icon: Icons.people_alt_rounded,
            ),
            PrivacyOptionCard(
              value: ContentPrivacy.private,
              currentValue: currentPrivacy,
              title: context.l10n.specificPeople,
              subtitle: context.l10n.onlySpecificPeopleYou,
              icon: Icons.lock_rounded,
            ),
          ],
        ),
      );
    },
  );
}
