import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

@immutable
class LottieColorRamp {
  final Color tint;
  final Color soft;
  final Color accent;
  final Color strong;
  final Color deep;
  final Color neutral;
  final Color doorBody;

  const LottieColorRamp({
    required this.tint,
    required this.soft,
    required this.accent,
    required this.strong,
    required this.deep,
    required this.neutral,
    required this.doorBody,
  });

  static Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

  factory LottieColorRamp.fromColorScheme(ColorScheme cs) {
    final p = cs.primary;

    if (cs.brightness == Brightness.dark) {
      return LottieColorRamp(
        tint: _mix(cs.surface, p, 0.22),
        soft: _mix(cs.surface, p, 0.38),
        accent: _mix(p, cs.surface, 0.30),
        strong: p,
        deep: _mix(p, Colors.black, 0.28),
        neutral: _mix(cs.onSurfaceVariant, cs.surface, 0.25),
        doorBody: _mix(Colors.white, p, 0.08),
      );
    }

    return LottieColorRamp(
      tint: _mix(cs.surface, p, 0.14),
      soft: _mix(cs.surface, p, 0.26),
      accent: _mix(p, Colors.white, 0.42),
      strong: _mix(p, Colors.white, 0.10),
      deep: _mix(p, Colors.black, 0.15),
      neutral: _mix(cs.onSurfaceVariant, cs.surface, 0.45),
      doorBody: Colors.white,
    );
  }

  LottieDelegates exitDoorDelegates() {
    return LottieDelegates(
      values: [
        ValueDelegate.color(const ['bg shape Outlines', '**'], value: tint),
        ValueDelegate.color(const ['x 2 Outlines', '**'], value: tint),

        ValueDelegate.color(const ['circulito Outlines', '**'], value: accent),
        ValueDelegate.color(const ['arrow Outlines', '**'], value: accent),

        ValueDelegate.color(const ['Door knob', 'pomo', '**'], value: accent),
        ValueDelegate.color(const [
          'Door knob',
          'pomo sombra',
          '**',
        ], value: deep),

        ValueDelegate.color(const [
          'door Outlines',
          'Group 1',
          '**',
        ], value: neutral),
        ValueDelegate.color(const [
          'door Outlines',
          'door side',
          '**',
        ], value: accent),
        ValueDelegate.color(const [
          'door Outlines',
          'Group 3',
          '**',
        ], value: soft),
        ValueDelegate.color(const [
          'door Outlines',
          'Group 6',
          '**',
        ], value: doorBody),

        ValueDelegate.color(const ['door frame Outlines', '**'], value: accent),
        ValueDelegate.color(const [
          'door frame Outlines',
          'Group 5',
          '**',
        ], value: strong),
        ValueDelegate.color(const [
          'door frame Outlines',
          'Group 6',
          '**',
        ], value: strong),
      ],
    );
  }
}
