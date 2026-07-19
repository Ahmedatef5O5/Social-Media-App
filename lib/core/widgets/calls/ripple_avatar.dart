import 'package:flutter/material.dart';

class RippleAvatar extends StatefulWidget {
  final Widget avatar;
  final double avatarDiameter;
  final Color rippleColor;
  final int rippleCount;
  final Duration duration;
  final double maxOpacity;

  final double growthFactor;

  const RippleAvatar({
    super.key,
    required this.avatar,
    required this.avatarDiameter,
    this.rippleColor = Colors.white,
    this.rippleCount = 3,
    this.duration = const Duration(milliseconds: 2800),
    this.maxOpacity = 0.28,
    this.growthFactor = 0.85,
  });

  @override
  State<RippleAvatar> createState() => _RippleAvatarState();
}

class _RippleAvatarState extends State<RippleAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stageSize = widget.avatarDiameter * 2.2;
    final ringSize = widget.avatarDiameter * 1.15;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: stageSize,
          height: stageSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              for (int i = 0; i < widget.rippleCount; i++)
                _buildRing(i / widget.rippleCount, ringSize),
              child!,
            ],
          ),
        );
      },
      child: widget.avatar,
    );
  }

  Widget _buildRing(double delay, double ringSize) {
    final t = (_controller.value + delay) % 1.0;
    final scale = 1.0 + t * widget.growthFactor;
    final opacity = (widget.maxOpacity * (1 - t)).clamp(0.0, 1.0);

    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: ringSize,
          height: ringSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.rippleColor.withValues(alpha: 0.85),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}
