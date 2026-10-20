import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_images.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

class AboutUsVersionFooter extends StatelessWidget {
  final bool isDark;
  final Color primary;

  const AboutUsVersionFooter({
    super.key,
    required this.isDark,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Divider(
          color:
              isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.grey.shade200,
        ),
        const Gap(16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset(AppImages.launcherApp, width: 22, height: 22),
            ),
            const Gap(8),
            Text(
              'Social Mate',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
        const Gap(8),
        Text(
          context.l10n.version100,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white30 : Colors.grey.shade600,
          ),
        ),
        const Gap(6),
        Text(
          context.l10n.socialAppAllRights(DateTime.now().year),
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white24 : Colors.grey.shade500,
          ),
        ),
        const Gap(20),
      ],
    );
  }
}
