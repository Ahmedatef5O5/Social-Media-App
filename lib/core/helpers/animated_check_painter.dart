import 'dart:math';

import 'package:flutter/material.dart';

class AnimatedCheckPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  AnimatedCheckPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final safeProgress = progress.clamp(0.0, 1.0);

    final circlePaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      pi * 2 * safeProgress,
      false,
      circlePaint,
    );

    if (safeProgress > 0.4) {
      final checkPaint =
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round;

      final path = Path();
      path.moveTo(size.width * 0.28, size.height * 0.52);
      path.lineTo(size.width * 0.45, size.height * 0.68);
      path.lineTo(size.width * 0.72, size.height * 0.35);

      final metrics = path.computeMetrics().toList();
      if (metrics.isNotEmpty) {
        final totalLength = metrics.first.length;
        final checkProgress = ((safeProgress - 0.4) / 0.6).clamp(0.0, 1.0);
        final extractPath = metrics.first.extractPath(
          0,
          totalLength * checkProgress,
        );
        canvas.drawPath(extractPath, checkPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant AnimatedCheckPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
