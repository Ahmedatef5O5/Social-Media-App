import 'package:flutter/material.dart';
import 'dart:math' as math;

class TypingIndicatorWidget extends StatefulWidget {
  final Color color;
  final double dotSize;
  final double spacing;

  const TypingIndicatorWidget({
    super.key,
    this.color = Colors.grey,
    this.dotSize = 4.0,
    this.spacing = 2.0,
  });

  @override
  State<TypingIndicatorWidget> createState() => _TypingIndicatorWidgetState();
}

class _TypingIndicatorWidgetState extends State<TypingIndicatorWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _controller,
      child: Container(
        width: widget.dotSize,
        height: widget.dotSize,
        margin: EdgeInsets.symmetric(horizontal: widget.spacing),
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
      builder: (context, child) {
        final double delay = index * 0.18;
        double t = (_controller.value - delay) % 1.0;
        if (t < 0) t += 1.0;

        double dy = 0.0;

        if (t < 0.45) {
          double scaledT = (t / 0.45) * math.pi;
          dy = -math.sin(scaledT) * (widget.dotSize * 1.5);
        }

        return Transform.translate(offset: Offset(0, dy), child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) => _buildDot(i)),
    );
  }
}
