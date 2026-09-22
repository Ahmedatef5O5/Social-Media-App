import 'package:flutter/material.dart';
import '../../../core/themes/app_colors.dart';

class ProfileUiTokens {
  ProfileUiTokens._({
    required this.isDark,
    required this.primary,
    required this.primaryTonal,
    required this.surface,
    required this.surfaceVariant,
    required this.outline,
    required this.onSurface,
    required this.onSurfaceVariant,
  });

  factory ProfileUiTokens.of(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return ProfileUiTokens._(
      isDark: isDark,
      primary: theme.primaryColor,
      primaryTonal: theme.primaryColor.withValues(alpha: isDark ? 0.22 : 0.12),
      surface: theme.colorScheme.surface,
      surfaceVariant: theme.colorScheme.surfaceContainerHighest,
      outline: isDark ? Colors.white.withValues(alpha: 0.18) : AppColors.grey3,
      onSurface: theme.colorScheme.onSurface,
      onSurfaceVariant: theme.colorScheme.onSurfaceVariant,
    );
  }

  final bool isDark;
  final Color primary;
  final Color primaryTonal;
  final Color surface;
  final Color surfaceVariant;
  final Color outline;
  final Color onSurface;
  final Color onSurfaceVariant;
  Color get onPrimary => Colors.white;
  Color get iconAccent => isDark ? Colors.white : primary;
  static const double screenPadding = 20;
  static const double buttonHeight = 46;
  static const double buttonRadius = 12;
  static const double cardRadius = 16;
  static const double iconButtonSize = 40;
}
