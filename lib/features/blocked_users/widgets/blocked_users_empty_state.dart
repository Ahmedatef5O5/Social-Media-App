import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../core/constants/app_images.dart';

class BlockedUsersEmptyState extends StatelessWidget {
  const BlockedUsersEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
              child: RepaintBoundary(
                child: Lottie.asset(
                  AppImages.blueSmileFaceLot,
                  height: MediaQuery.of(context).size.height * 0.12,
                  repeat: true,
                  delegates: LottieDelegates(
                    values: [
                      ValueDelegate.colorFilter(
                        ['**'],
                        value: ColorFilter.mode(
                          theme.primaryColor,
                          BlendMode.srcIn,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Blocked Users',
              style: theme.textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Accounts you block will show up here so you can manage them anytime.",
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
