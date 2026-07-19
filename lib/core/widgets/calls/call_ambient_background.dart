import 'dart:math' as math;
import 'package:flutter/material.dart';

enum CallAmbientStyle { orbit, drift }

class CallAmbientBackground extends StatefulWidget {
  final CallAmbientStyle style;
  final bool isVideo;

  const CallAmbientBackground({
    super.key,
    required this.style,
    required this.isVideo,
  });

  @override
  State<CallAmbientBackground> createState() => _CallAmbientBackgroundState();
}

class _CallAmbientBackgroundState extends State<CallAmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool get _isOrbit => widget.style == CallAmbientStyle.orbit;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration:
          _isOrbit
              ? const Duration(milliseconds: 3000)
              : const Duration(seconds: 8),
    )..repeat(reverse: _isOrbit);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return _isOrbit
                  ? _OrbitOrnaments(
                    t: _controller.value,
                    isVideo: widget.isVideo,
                    size: constraints.biggest,
                  )
                  : CustomPaint(
                    painter: _DriftParticlesPainter(
                      progress: _controller.value,
                    ),
                    size: constraints.biggest,
                  );
            },
          );
        },
      ),
    );
  }
}

class _OrbitOrnaments extends StatelessWidget {
  final double t; 
  final bool isVideo;
  final Size size;

  const _OrbitOrnaments({
    required this.t,
    required this.isVideo,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final float = (t - 0.5) * 20;
    final shortest = math.min(size.width, size.height);

    return Stack(
      children: [
        Positioned(
          top: size.height * 0.06 + float,
          right: -shortest * 0.12,
          child: Opacity(
            opacity: 0.08,
            child: Icon(
              isVideo ? Icons.videocam_rounded : Icons.phone_rounded,
              size: shortest * 0.42,
              color: Colors.white,
            ),
          ),
        ),
        Positioned(
          bottom: size.height * 0.14 - float,
          left: -shortest * 0.16,
          child: Opacity(
            opacity: 0.06,
            child: Container(
              width: shortest * 0.4,
              height: shortest * 0.4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: shortest * 0.045,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: size.height * 0.32 - float * 0.5,
          left: shortest * 0.04,
          child: Opacity(
            opacity: 0.08,
            child: _DotGrid(size: shortest * 0.14),
          ),
        ),
      ],
    );
  }
}

class _DotGrid extends StatelessWidget {
  final double size;

  const _DotGrid({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: 16,
        itemBuilder:
            (_, __) => const DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
      ),
    );
  }
}

class _DriftParticlesPainter extends CustomPainter {
  final double progress;
  static const _count = 14;

  _DriftParticlesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < _count; i++) {
      final seed = (i * 137.5) % 360;
      final x = (seed / 360) * size.width;
      final yProgress = (progress + i / _count) % 1.0;
      final y = size.height * (1 - yProgress);
      final radius = 2.0 + (i % 4) * 1.5;
      final opacity = (1 - yProgress).clamp(0.0, 1.0) * 0.55;
      canvas.drawCircle(
        Offset(x + math.sin(progress * math.pi * 2 + seed) * 20, y),
        radius,
        Paint()..color = Colors.white.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_DriftParticlesPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
