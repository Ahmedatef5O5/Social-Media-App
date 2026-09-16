import 'package:flutter/material.dart';

class AiChatColors {
  const AiChatColors._();

  static List<Color> backgroundGradient(Color primary) {
    final hsl = HSLColor.fromColor(primary);
    final top =
        hsl
            .withLightness(0.22)
            .withSaturation((hsl.saturation * 0.85).clamp(0.0, 1.0))
            .toColor();
    final bottom =
        hsl
            .withLightness(0.05)
            .withSaturation((hsl.saturation * 0.55).clamp(0.0, 1.0))
            .toColor();
    return [top, bottom];
  }

  static (Color base, Color highlight) shimmerTones(Color primary) {
    final hsl = HSLColor.fromColor(primary);
    final base =
        hsl
            .withLightness(0.16)
            .withSaturation((hsl.saturation * 0.45).clamp(0.0, 1.0))
            .toColor();
    final highlight =
        hsl
            .withLightness(0.30)
            .withSaturation((hsl.saturation * 0.35).clamp(0.0, 1.0))
            .toColor();
    return (base, highlight);
  }

  static List<Color> outgoingBubbleGradient(Color primary) {
    final hsl = HSLColor.fromColor(primary);
    final start =
        hsl.withLightness((hsl.lightness + 0.08).clamp(0.0, 1.0)).toColor();
    final end =
        hsl.withLightness((hsl.lightness - 0.12).clamp(0.0, 1.0)).toColor();
    return [start, end];
  }

  static Color _highlightSeed(Color primary) {
    final hsl = HSLColor.fromColor(primary);
    return hsl
        .withLightness((hsl.lightness + 0.30).clamp(0.0, 0.82))
        .withSaturation((hsl.saturation * 0.55 + 0.25).clamp(0.0, 1.0))
        .toColor();
  }

  static Color highlightFill(Color primary) =>
      _highlightSeed(primary).withValues(alpha: 0.42);

  static Color highlightStroke(Color primary) =>
      _highlightSeed(primary).withValues(alpha: 0.85);

  static Color highlightGlow(Color primary) =>
      _highlightSeed(primary).withValues(alpha: 0.40);
}
