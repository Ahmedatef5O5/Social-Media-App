import 'package:flutter/material.dart';

class LinkColorHelper {
  const LinkColorHelper._();

  static Color forBubble(Color bubbleColor) {
    const classicBlue = Colors.blue;
    final bubbleHsl = HSLColor.fromColor(bubbleColor);
    if (bubbleHsl.saturation < 0.22) return classicBlue;

    final linkHsl = HSLColor.fromColor(classicBlue);
    if (_hueDistance(bubbleHsl.hue, linkHsl.hue) > 45) return classicBlue;

    final targetLightness = bubbleHsl.lightness < 0.5 ? 0.80 : 0.26;
    return linkHsl
        .withLightness(targetLightness)
        .withSaturation((linkHsl.saturation * 0.92).clamp(0.0, 1.0))
        .toColor();
  }

  static double _hueDistance(double a, double b) {
    final diff = (a - b).abs() % 360;
    return diff > 180 ? 360 - diff : diff;
  }
}
