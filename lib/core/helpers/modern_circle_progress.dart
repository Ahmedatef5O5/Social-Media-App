import 'package:flutter/material.dart';
import 'package:social_media_app/core/helpers/modern_progress_painter.dart';

class ModernCircularProgress extends StatelessWidget {
  final double progress;
  final double size;

  const ModernCircularProgress({
    super.key,
    required this.progress,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final bgCircleColor =
        theme.brightness == Brightness.light
            ? Colors.grey[300]!
            : Colors.grey[800]!;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RepaintBoundary(
            child: CustomPaint(
              size: Size(size, size),
              painter: ModernProgressPainter(
                progress: progress,
                backgroundColor: bgCircleColor,
                progressColor: primaryColor,
              ),
            ),
          ),

          Text(
            "${(progress * 100).toInt()}%",
            style: theme.textTheme.headlineSmall?.copyWith(
              color:
                  theme.brightness == Brightness.light
                      ? Theme.of(context).primaryColor.withValues(alpha: 0.7)
                      // Colors.black87
                      : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: size * 0.28,
            ),
          ),
        ],
      ),
    );
  }
}
