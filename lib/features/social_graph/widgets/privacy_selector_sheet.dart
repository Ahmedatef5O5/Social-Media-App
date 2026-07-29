import 'package:flutter/material.dart';
import '../models/content_privacy.dart';
import 'privacy_option_card.dart';

Future<ContentPrivacy?> showPrivacySelectorSheet(
  BuildContext context, {
  required ContentPrivacy currentPrivacy,
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
              'Who can see this?',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose your audience for this story',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),

            PrivacyOptionCard(
              value: ContentPrivacy.public,
              currentValue: currentPrivacy,
              title: 'Public',
              subtitle: 'Anyone on the app can see this',
              icon: Icons.public_rounded,
            ),
            PrivacyOptionCard(
              value: ContentPrivacy.friends,
              currentValue: currentPrivacy,
              title: 'Friends',
              subtitle: 'Only your friends can see this',
              icon: Icons.people_alt_rounded,
            ),
            PrivacyOptionCard(
              value: ContentPrivacy.private,
              currentValue: currentPrivacy,
              title: 'Specific people',
              subtitle: 'Only specific people you choose',
              icon: Icons.lock_rounded,
            ),
          ],
        ),
      );
    },
  );
}
