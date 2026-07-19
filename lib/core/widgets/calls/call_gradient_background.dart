import 'package:flutter/material.dart';

class CallGradientBackground extends StatelessWidget {
  final Color baseColor;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;

  const CallGradientBackground({
    super.key,
    required this.baseColor,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  });

  @override
  Widget build(BuildContext context) {
    final hsl = HSLColor.fromColor(baseColor);
    final mid =
        hsl.withLightness((hsl.lightness - 0.10).clamp(0.0, 1.0)).toColor();
    final darker =
        hsl.withLightness((hsl.lightness - 0.22).clamp(0.0, 1.0)).toColor();

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors: [baseColor, mid, darker],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}
