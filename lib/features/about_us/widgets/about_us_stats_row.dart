import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

class AboutUsStatsRow extends StatelessWidget {
  final bool isDark;
  final Color primary;

  const AboutUsStatsRow({
    super.key,
    required this.isDark,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      ('50K+', context.l10n.aboutStatUsers),
      ('1M+', context.l10n.aboutStatMessages),
      ('200K+', context.l10n.aboutStatPosts),
      ('99.9%', context.l10n.aboutStatUptime),
    ];
    return Row(
      children:
          stats.map((s) {
            final isLast = s == stats.last;
            return Expanded(
              child: Container(
                margin: EdgeInsetsDirectional.only(end: isLast ? 0 : 8),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        isDark
                            ? Colors.white.withValues(alpha: 0.07)
                            : Colors.grey.shade200,
                    width: 0.8,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      s.$1,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: primary,
                        letterSpacing: context.ls(-0.5),
                      ),
                    ),
                    const Gap(4),
                    Text(
                      s.$2,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }
}
