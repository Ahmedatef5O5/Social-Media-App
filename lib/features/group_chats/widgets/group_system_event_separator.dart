import 'package:flutter/material.dart';

class GroupSystemEventSeparator extends StatelessWidget {
  final String text;
  const GroupSystemEventSeparator({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    final Color textColor =
        isDark
            ? colorScheme.onSurface.withValues(alpha: 0.6)
            : colorScheme.onSurfaceVariant.withValues(alpha: 0.55);
    final Color containerColor =
        isDark
            ? Colors.white.withValues(alpha: 0.10)
            : colorScheme.onSurfaceVariant.withValues(alpha: 0.05);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: containerColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: textColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
