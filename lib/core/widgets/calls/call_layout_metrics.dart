import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Single source of truth for adaptive sizing across every call screen
/// (dialing, incoming, ongoing — 1:1 and group). Replaces the old
/// width-only `shortest.clamp(...) * factor` formulas, which sized the
/// avatar/buttons off screen WIDTH with no regard for available HEIGHT —
/// the root cause of the reported 7.7px RenderFlex overflow on short
/// viewports.
class CallLayoutMetrics {
  final double avatarDiameter;
  final double buttonSize;
  final double topGap;
  final double midGap;
  final double bottomGap;
  final bool isCompact;

  const CallLayoutMetrics._({
    required this.avatarDiameter,
    required this.buttonSize,
    required this.topGap,
    required this.midGap,
    required this.bottomGap,
    required this.isCompact,
  });

  /// [reservedHeight] is the approximate combined height of everything
  /// in the column that ISN'T the avatar (status pill, name, subtitle,
  /// action buttons + their labels, base gaps) — pass a slightly higher
  /// number when a screen has extra chrome (e.g. two buttons stacked
  /// with labels vs. one).
  factory CallLayoutMetrics.of(
    BoxConstraints constraints, {
    double reservedHeight = 260,
  }) {
    final shortest = constraints.biggest.shortestSide;
    final availableHeight = constraints.maxHeight;
    final isCompact = availableHeight < 620;

    // RippleAvatar's stage is avatarDiameter * 2.2 tall — solve backwards
    // from the height budget actually left over for it.
    final heightBudget = (availableHeight - reservedHeight).clamp(
      120.0,
      double.infinity,
    );
    final avatarFromWidth = shortest.clamp(280.0, 460.0) * 0.34;
    final avatarFromHeight = heightBudget / 2.2;
    final avatarDiameter = math
        .min(avatarFromWidth, avatarFromHeight)
        .clamp(72.0, 170.0);

    final buttonSize = (shortest.clamp(280.0, 460.0) * 0.19).clamp(56.0, 84.0);

    return CallLayoutMetrics._(
      avatarDiameter: avatarDiameter,
      buttonSize: buttonSize,
      topGap: isCompact ? 16 : 40,
      midGap: isCompact ? 14 : 24,
      bottomGap: isCompact ? 24 : 56,
      isCompact: isCompact,
    );
  }
}
