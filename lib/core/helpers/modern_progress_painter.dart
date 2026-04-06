import 'dart:math';
import 'package:flutter/material.dart';

class ModernProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;

  ModernProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.12;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final backgroundPaint =
        Paint()
          ..color = backgroundColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, backgroundPaint);

    final progressPaint =
        Paint()
          ..color = progressColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..shader = SweepGradient(
            colors: [progressColor.withValues(alpha: 0.8), progressColor],
            startAngle: -pi / 2,
            endAngle: pi * 2 * progress - pi / 2,
          ).createShader(
            Rect.fromCircle(
              center: center,
              radius: radius.abs() > 0 ? radius : 1.0,
            ),
          );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      pi * 2 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant ModernProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor;
  }
}
