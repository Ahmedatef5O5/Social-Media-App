import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedAiStarsIcon extends StatefulWidget {
  final double size;
  final Color? color;

  const AnimatedAiStarsIcon({super.key, this.size = 22, this.color});

  @override
  State<AnimatedAiStarsIcon> createState() => _AnimatedAiStarsIconState();
}

class _AnimatedAiStarsIconState extends State<AnimatedAiStarsIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).primaryColor;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              _buildSparkle(
                color: color,
                phase: 0.0,
                starSize: widget.size * 0.54,
                alignment: const Alignment(-0.55, 0.20),
              ),
              _buildSparkle(
                color: color,
                phase: 0.33,
                starSize: widget.size * 0.32,
                alignment: const Alignment(0.65, -0.70),
              ),
              _buildSparkle(
                color: color,
                phase: 0.66,
                starSize: widget.size * 0.24,
                alignment: const Alignment(0.52, 0.75),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSparkle({
    required Color color,
    required double phase,
    required double starSize,
    required Alignment alignment,
  }) {
    final angle = (_controller.value - phase) * 2 * math.pi;
    final pulse = (math.sin(angle) + 1) / 2;

    final scale = 0.52 + (0.56 * pulse);
    final opacity = 0.35 + (0.65 * pulse);

    return Align(
      alignment: alignment,
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity,
          child: CustomPaint(
            size: Size(starSize, starSize),
            painter: _SparklePainter(color: color),
          ),
        ),
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  final Color color;

  _SparklePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    final path = Path();
    final w = size.width;
    final h = size.height;

    final cx = w / 2;
    final cy = h / 2;

    path.moveTo(cx, 0);
    path.quadraticBezierTo(cx, cy, w, cy);
    path.quadraticBezierTo(cx, cy, cx, h);
    path.quadraticBezierTo(cx, cy, 0, cy);
    path.quadraticBezierTo(cx, cy, cx, 0);

    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
