import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'thought_bubble_shape.dart';

class ThoughtBubbleRipple extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final ThoughtCloudPath cloud;
  final VoidCallback onTap;

  const ThoughtBubbleRipple({
    super.key,
    required this.child,
    required this.glowColor,
    required this.cloud,
    required this.onTap,
  });

  @override
  State<ThoughtBubbleRipple> createState() => _ThoughtBubbleRippleState();
}

class _ThoughtBubbleRippleState extends State<ThoughtBubbleRipple>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );

  late final Animation<double> _glowOpacity = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 35),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 65),
  ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.04), weight: 35),
    TweenSequenceItem(tween: Tween(begin: 1.04, end: 1.0), weight: 65),
  ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (_controller.isAnimating) return;
    HapticFeedback.selectionClick();
    _controller.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: CustomPaint(
              painter: _CloudGlowPainter(
                cloud: widget.cloud,
                color: widget.glowColor.withValues(
                  alpha: 0.45 * _glowOpacity.value,
                ),
              ),
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

class _CloudGlowPainter extends CustomPainter {
  const _CloudGlowPainter({
    required this.cloud,
    required this.color,
    this.blurRadius = 18,
    this.spread = 2,
  });

  final ThoughtCloudPath cloud;
  final Color color;
  final double blurRadius;
  final double spread;

  @override
  void paint(Canvas canvas, Size size) {
    if (color.a == 0) return;

    final path = cloud.build(size);
    final paint =
        Paint()
          ..color = color
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            ui.Shadow.convertRadiusToSigma(blurRadius),
          );

    canvas.drawPath(path, paint);

    if (spread > 0) {
      canvas.drawPath(
        path,
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = spread * 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CloudGlowPainter oldDelegate) =>
      oldDelegate.cloud != cloud ||
      oldDelegate.color != color ||
      oldDelegate.blurRadius != blurRadius ||
      oldDelegate.spread != spread;
}
