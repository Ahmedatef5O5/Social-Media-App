import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

/// Card surface that matches `SettingsSection` (same fill, border, radius).
class SettingsSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? accent;

  const SettingsSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = this.accent;

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color:
            accent != null
                ? accent.withValues(alpha: isDark ? 0.10 : 0.07)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              accent != null
                  ? accent.withValues(alpha: 0.35)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.07)
                      : Colors.black.withValues(alpha: 0.06)),
          width: 0.8,
        ),
      ),
      child: child,
    );
  }
}

enum SettingsBannerTone { info, warning, success }

/// Icon + message banner used for hints, OAuth notices and warnings.
class SettingsInfoBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? title;
  final SettingsBannerTone tone;

  const SettingsInfoBanner({
    super.key,
    required this.icon,
    required this.message,
    this.title,
    this.tone = SettingsBannerTone.info,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = switch (tone) {
      SettingsBannerTone.info => theme.primaryColor,
      SettingsBannerTone.warning =>
        isDark ? Colors.amber.shade300 : Colors.amber.shade800,
      SettingsBannerTone.success =>
        isDark ? Colors.green.shade300 : Colors.green.shade700,
    };

    return SettingsSurfaceCard(
      accent: color,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Gap(3),
                ],
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
