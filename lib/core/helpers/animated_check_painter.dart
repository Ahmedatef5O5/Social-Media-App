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
    final safeProgress = progress.clamp(0.0, 1.0);
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(size.width * 0.25, size.height * 0.5);
    path.lineTo(size.width * 0.45, size.height * 0.7);
    path.lineTo(size.width * 0.75, size.height * 0.35);

    final metrics = path.computeMetrics().toList();
    if (metrics.isNotEmpty) {
      final totalLength = metrics.first.length;
      final extractLength = totalLength * safeProgress;
      if (extractLength > 0) {
        final extractPath = metrics.first.extractPath(0, extractLength);
        canvas.drawPath(extractPath, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant AnimatedCheckPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
