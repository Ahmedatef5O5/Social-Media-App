import 'package:flutter/material.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';
import '../../../core/constants/app_images.dart';

class BlockedUsersEmptyState extends StatelessWidget {
  const BlockedUsersEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final imageSize = (MediaQuery.sizeOf(context).width * 0.32).clamp(
      120.0,
      180.0,
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.primaryColor.withValues(alpha: 0.06),
              ),
              child: Image.asset(
                AppImages.blockedUserIcon,
                width: imageSize,
                height: imageSize,
                fit: BoxFit.contain,
                color: theme.primaryColor.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              context.l10n.noBlockedUsers,
              style: theme.textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.accountsYouBlockWill,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium!.copyWith(
                color: isDark ? Colors.white60 : Colors.black54,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
