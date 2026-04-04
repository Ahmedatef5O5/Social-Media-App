import 'dart:ui';
import 'package:flutter/material.dart';

class DateSeparatorGlassmorphismWidget extends StatelessWidget {
  final String date;
  const DateSeparatorGlassmorphismWidget({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final Color textColor =
        isDark
            ? colorScheme.onSurface.withValues(alpha: 0.7)
            : colorScheme.onSurfaceVariant.withValues(alpha: 0.65);
    final Color containerColor =
        isDark
            ? Colors.white.withValues(alpha: 0.24)
            : colorScheme.onSurfaceVariant.withValues(alpha: 0.03);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color:
                      isDark
                          ? Colors.white70.withValues(alpha: 0.15)
                          : colorScheme.outlineVariant.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Text(
                date,
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
