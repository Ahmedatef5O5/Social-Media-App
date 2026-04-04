import 'dart:ui';
import 'package:flutter/material.dart';

class DateSeparatorGlassmorphismWidget extends StatelessWidget {
  final String date;
  const DateSeparatorGlassmorphismWidget({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    final Color surfaceColor = Theme.of(
      context,
    ).colorScheme.surface.withValues(alpha: 0.4);
    final Color onSurfaceColor = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: onSurfaceColor.withValues(alpha: 0.08),
                  width: 0.8,
                ),
              ),
              child: Text(
                date,
                style: TextStyle(
                  color: onSurfaceColor.withValues(alpha: 0.65),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
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
