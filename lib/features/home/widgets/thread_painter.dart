import 'package:flutter/material.dart';
import '../../../core/helpers/comment_helper.dart';
import 'comment_constants.dart';

class ThreadPainter extends CustomPainter {
  final int depth;
  final double avatarCenterX;
  final double currentAvatarRadius;
  final bool showVerticalStem;
  final double? stemEndY;
  final Color lineColor;

  const ThreadPainter({
    required this.depth,
    required this.avatarCenterX,
    required this.currentAvatarRadius,
    required this.showVerticalStem,
    this.stemEndY,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = lineColor
          ..strokeWidth = 1.6
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final double avatarCenterY = currentAvatarRadius;

    if (depth >= 1 && depth < 3) {
      final double parentAvatarR = avatarRadius(depth - 1);
      final double parentLineX = (depth - 1) * kIndent + parentAvatarR;

      final double cornerR = (avatarCenterY * 0.6).clamp(4.0, 10.0);
      const double avatarCurveGap = 4;

      final path =
          Path()
            ..moveTo(parentLineX, 0)
            ..lineTo(parentLineX, avatarCenterY - cornerR)
            ..quadraticBezierTo(
              parentLineX,
              avatarCenterY,
              parentLineX + cornerR,
              avatarCenterY,
            )
            ..lineTo(
              avatarCenterX - currentAvatarRadius - avatarCurveGap,
              avatarCenterY,
            );

      canvas.drawPath(path, paint);
    }

    if (showVerticalStem && stemEndY != null) {
      final double stemGap = currentAvatarRadius * 0.35;
      final double stemTop = avatarCenterY + currentAvatarRadius + stemGap;

      final bool isDeepLevel = depth >= 2;

      final double stemBottom =
          isDeepLevel
              ? stemEndY! - (currentAvatarRadius * 1.4)
              : stemEndY! - (currentAvatarRadius * 0.7);

      if (stemBottom > stemTop + 4) {
        canvas.drawLine(
          Offset(avatarCenterX, stemTop),
          Offset(avatarCenterX, stemBottom),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant ThreadPainter old) => true;
}
