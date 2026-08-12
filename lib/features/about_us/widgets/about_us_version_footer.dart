import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

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
              child: Icon(Icons.people_alt_rounded, color: primary, size: 14),
            ),
            const Gap(8),
            Text(
              'Social App',
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
          'Version 1.0.0  •  Made with ❤️',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white30 : Colors.grey.shade600,
          ),
        ),
        const Gap(6),
        Text(
          '© ${DateTime.now().year} Social App. All rights reserved.',
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
