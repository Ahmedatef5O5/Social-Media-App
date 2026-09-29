import 'package:flutter/material.dart';

class ThoughtTrailDots extends StatelessWidget {
  final List<Offset> dotCenters;
  final List<double> dotRadii;
  final Color primary;
  final Color surface;
  final bool isDark;

  const ThoughtTrailDots({
    super.key,
    required this.dotCenters,
    required this.dotRadii,
    required this.primary,
    required this.surface,
    required this.isDark,
  }) : assert(dotCenters.length == dotRadii.length);

  @override
  Widget build(BuildContext context) {
    final int count = dotCenters.length;

    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < count; i++)
            Positioned(
              left: dotCenters[i].dx - dotRadii[i],
              top: dotCenters[i].dy - dotRadii[i],
              child: _PearlDot(
                radius: dotRadii[i],
                depth: count > 1 ? i / (count - 1) : 1.0,
                primary: primary,
                surface: surface,
                isDark: isDark,
              ),
            ),
        ],
      ),
    );
  }
}

class _PearlDot extends StatelessWidget {
  final double radius;
  final double depth;
  final Color primary;
  final Color surface;
  final bool isDark;

  const _PearlDot({
    required this.radius,
    required this.depth,
    required this.primary,
    required this.surface,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final double topAlpha = (isDark ? 0.20 : 0.10) + 0.06 * depth;
    final double bottomAlpha = (isDark ? 0.42 : 0.30) + 0.14 * depth;

    final Color topColor = Color.alphaBlend(
      primary.withValues(alpha: topAlpha),
      surface,
    );
    final Color bottomColor = Color.alphaBlend(
      primary.withValues(alpha: bottomAlpha),
      surface,
    );

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [topColor, bottomColor],
        ),
        border: Border.all(
          color: primary.withValues(alpha: isDark ? 0.45 : 0.28),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: isDark ? 0.28 : 0.16),
            blurRadius: 5 + radius * 0.5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}
