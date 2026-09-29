import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';


class ThoughtCloudPath {

  final double crown;
  final double belly;
  final double inset;

  const ThoughtCloudPath({
    this.crown = 4.5,
    this.belly = 2.5,
    this.inset = 1.0,
  });


  static const List<(double, double, double)> _crownPuffs = [
    (0.25, 0.15, 0.72),
    (0.53, 0.20, 1.0),
    (0.79, 0.13, 0.62),
  ];

  static const List<(double, double, double)> _bellyPuffs = [
    (0.36, 0.17, 1.0),
    (0.70, 0.14, 0.6),
  ];

  static const double _maxPuffHalfWidth = 26;

  Path build(Size size) {
    final double left = inset;
    final double right = size.width - inset;
    final double top = inset + crown;
    final double bottom = size.height - inset - belly;
    final double bodyWidth = right - left;
    final double bodyHeight = bottom - top;

    Path path =
        Path()..addRRect(
          RRect.fromLTRBR(
            left,
            top,
            right,
            bottom,
            Radius.circular(bodyHeight / 2),
          ),
        );

    final double ridge = bodyHeight * 0.22;

    for (final (centerFraction, halfWidthFraction, scale) in _crownPuffs) {
      final double bulge = crown * scale;
      final double halfWidth = math.min(
        bodyWidth * halfWidthFraction,
        _maxPuffHalfWidth,
      );
      final double cx = left + bodyWidth * centerFraction;
      path = Path.combine(
        PathOperation.union,
        path,
        Path()..addOval(
          Rect.fromCenter(
            center: Offset(cx, top + ridge),
            width: halfWidth * 2,
            height: (bulge + ridge) * 2,
          ),
        ),
      );
    }

    for (final (centerFraction, halfWidthFraction, scale) in _bellyPuffs) {
      final double bulge = belly * scale;
      final double halfWidth = math.min(
        bodyWidth * halfWidthFraction,
        _maxPuffHalfWidth,
      );
      final double cx = left + bodyWidth * centerFraction;
      path = Path.combine(
        PathOperation.union,
        path,
        Path()..addOval(
          Rect.fromCenter(
            center: Offset(cx, bottom - ridge),
            width: halfWidth * 2,
            height: (bulge + ridge) * 2,
          ),
        ),
      );
    }

    return path;
  }

  @override
  bool operator ==(Object other) =>
      other is ThoughtCloudPath &&
      other.crown == crown &&
      other.belly == belly &&
      other.inset == inset;

  @override
  int get hashCode => Object.hash(crown, belly, inset);
}

class ThoughtCloudClipper extends CustomClipper<Path> {
  const ThoughtCloudClipper({required this.cloud});

  final ThoughtCloudPath cloud;

  @override
  Path getClip(Size size) => cloud.build(size);

  @override
  bool shouldReclip(covariant ThoughtCloudClipper oldClipper) =>
      oldClipper.cloud != cloud;
}

class ThoughtCloudShadowPainter extends CustomPainter {
  const ThoughtCloudShadowPainter({
    required this.cloud,
    required this.color,
    this.blurRadius = 10,
    this.offset = const Offset(0, 4),
  });

  final ThoughtCloudPath cloud;
  final Color color;
  final double blurRadius;
  final Offset offset;

  @override
  void paint(Canvas canvas, Size size) {
    final path = cloud.build(size).shift(offset);
    final paint =
        Paint()
          ..color = color
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            ui.Shadow.convertRadiusToSigma(blurRadius),
          );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ThoughtCloudShadowPainter oldDelegate) =>
      oldDelegate.cloud != cloud ||
      oldDelegate.color != color ||
      oldDelegate.blurRadius != blurRadius ||
      oldDelegate.offset != offset;
}

class ThoughtBubbleBorderPainter extends CustomPainter {
  const ThoughtBubbleBorderPainter({
    required this.cloud,
    required this.borderColor,
    required this.highlightColor,
    this.strokeWidth = 1.15,
  });

  final ThoughtCloudPath cloud;
  final Color borderColor;
  final Color highlightColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final path = cloud.build(size);

    canvas.save();
    canvas.clipPath(path);
    final highlightPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..shader = ui.Gradient.linear(
            Offset(0, cloud.inset),
            Offset(0, size.height * 0.62),
            [highlightColor, highlightColor.withValues(alpha: 0)],
          );
    canvas.drawPath(path.shift(const Offset(0, 1.4)), highlightPaint);
    canvas.restore();

    final borderPaint =
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant ThoughtBubbleBorderPainter oldDelegate) =>
      oldDelegate.cloud != cloud ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.highlightColor != highlightColor ||
      oldDelegate.strokeWidth != strokeWidth;
}
