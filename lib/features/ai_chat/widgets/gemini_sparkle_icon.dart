import 'package:flutter/material.dart';

/// Authentic Google Gemini 4-pointed sparkle icon.
/// Uses official cubic bezier curve geometry for a fuller, bolder silhouette
/// and Google's signature 4-color vibrant blend (Red, Yellow, Green, Blue).
class GeminiSparkleIcon extends StatelessWidget {
  final double size;
  final Color? color;
  final Gradient? gradient;

  const GeminiSparkleIcon({
    super.key,
    this.size = 20,
    this.color,
    this.gradient,
  });

  /// The authentic Google Gemini rich 4-color gradient:
  /// Vivid Red (Top) -> Gold (Left) -> Green (Bottom) -> Electric Blue (Right).
  static const Gradient defaultGradient = SweepGradient(
    center: Alignment.center,
    startAngle: 0.0,
    endAngle: 6.2831853, // 2 * PI
    colors: [
      Color(0xFF1A73E8), // Vivid Blue (Right - 0 deg)
      Color(0xFF34A853), // Emerald Green (Bottom - 90 deg)
      Color(0xFFFBBC05), // Amber Gold (Left - 180 deg)
      Color(0xFFEA4335), // Coral Red (Top - 270 deg)
      Color(0xFF1A73E8), // Loop back to Blue
    ],
    stops: [0.0, 0.28, 0.52, 0.78, 1.0],
  );

  @override
  Widget build(BuildContext context) {
    // Slight optical boost (+15%) so the 4-pointed star visually matches
    // the weight of circular and full-bodied icons like Meta and OpenRouter.
    final visualSize = size * 1.15;

    return SizedBox(
      width: visualSize,
      height: visualSize,
      child: Center(
        child: CustomPaint(
          size: Size(visualSize, visualSize),
          painter: _GeminiSparklePainter(
            color: color,
            gradient: color != null ? null : (gradient ?? defaultGradient),
          ),
        ),
      ),
    );
  }
}

class _GeminiSparklePainter extends CustomPainter {
  final Color? color;
  final Gradient? gradient;

  const _GeminiSparklePainter({this.color, this.gradient});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Official Google Gemini Cubic Bezier curve ratios (0.276 / 0.724)
    // for a plump, distinct body instead of needle-thin points.
    final path =
        Path()
          ..moveTo(w * 0.5, 0)
          // Top vertex to Right vertex
          ..cubicTo(w * 0.5, h * 0.276, w * 0.724, h * 0.5, w, h * 0.5)
          // Right vertex to Bottom vertex
          ..cubicTo(w * 0.724, h * 0.5, w * 0.5, h * 0.724, w * 0.5, h)
          // Bottom vertex to Left vertex
          ..cubicTo(w * 0.5, h * 0.724, w * 0.276, h * 0.5, 0, h * 0.5)
          // Left vertex back to Top vertex
          ..cubicTo(w * 0.276, h * 0.5, w * 0.5, h * 0.276, w * 0.5, 0)
          ..close();

    final paint =
        Paint()
          ..isAntiAlias = true
          ..filterQuality = FilterQuality.high
          ..style = PaintingStyle.fill;

    if (gradient != null) {
      paint.shader = gradient!.createShader(Rect.fromLTWH(0, 0, w, h));
    } else {
      paint.color = color ?? const Color(0xFF4285F4);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _GeminiSparklePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.gradient != gradient;
}
