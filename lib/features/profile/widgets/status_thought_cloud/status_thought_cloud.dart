import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/profile_ui_tokens.dart';
import 'thought_bubble_ripple.dart';
import 'thought_bubble_shape.dart';
import 'thought_cloud_geometry.dart';
import 'thought_trail_dots.dart';

class StatusThoughtCloud extends StatelessWidget {
  final String? tagline;
  final bool isMe;
  final bool isHidden;
  final double screenWidth;
  final double backgroundHeight;
  final double avatarSize;
  final VoidCallback onEditRequested;

  const StatusThoughtCloud({
    super.key,
    required this.tagline,
    required this.isMe,
    required this.isHidden,
    required this.screenWidth,
    required this.backgroundHeight,
    required this.avatarSize,
    required this.onEditRequested,
  });

  static const List<double> _dotRadii = [3.2, 4.8, 6.8];
  static const List<Offset> _dotOffsetsFromOrigin = [
    Offset(5, 8),
    Offset(10, 17),
    Offset(21, 24),
  ];

  static const double _bubbleLeftFromOrigin = 28;
  static const double _bubbleTopFromBackground = 5;
  static const double _bubbleBottomBound = 2;
  static const double _bubbleMinWidth = 84;
  static const double _availableWidthMin = 88;
  static const double _availableWidthMax = 148;
  static const double _oneLineHeight = 38;
  static const double _twoLineHeight = 44;
  static const double _iconZoneSafetyWidth = 98;

  bool get _hasTagline => tagline != null && tagline!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (isHidden) return const SizedBox.shrink();
    if (!isMe && !_hasTagline) return const SizedBox.shrink();

    final tokens = ProfileUiTokens.of(context);
    final geometry = ThoughtCloudGeometry.fromProfileHeader(
      screenWidth: screenWidth,
      backgroundHeight: backgroundHeight,
      avatarSize: avatarSize,
    );
    final origin = geometry.originOnAvatarEdge;

    final dotCenters = [
      for (final offset in _dotOffsetsFromOrigin) origin + offset,
    ];

    // ── Horizontal band ──
    final bubbleLeft = origin.dx + _bubbleLeftFromOrigin;
    final availableWidth = (screenWidth -
            bubbleLeft -
            ProfileUiTokens.screenPadding -
            _iconZoneSafetyWidth)
        .clamp(_availableWidthMin, _availableWidthMax);

    final bubbleTop = backgroundHeight + _bubbleTopFromBackground;
    final maxBubbleHeight = math.max(
      28.0,
      avatarSize / 2 + _bubbleBottomBound - _bubbleTopFromBackground,
    );

    final displayText = _hasTagline ? tagline!.trim() : 'Add a status ✨';

    final fit = _resolveTaglineFit(
      text: displayText,
      availableWidth: availableWidth,
      minWidth: _bubbleMinWidth,
      maxBubbleHeight: maxBubbleHeight,
      textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.15),
      isPlaceholder: !_hasTagline,
    );

    const cloud = ThoughtCloudPath();

    final bubble = _ThoughtBubbleContent(
      text: displayText,
      isPlaceholder: !_hasTagline,
      fit: fit,
      cloud: cloud,
      tokens: tokens,
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: ThoughtTrailDots(
            dotCenters: dotCenters,
            dotRadii: _dotRadii,
            primary: tokens.primary,
            surface: tokens.surface,
            isDark: tokens.isDark,
          ),
        ),
        Positioned(
          left: bubbleLeft,
          top: bubbleTop,
          width: fit.width,
          height: fit.height,
          child:
              isMe
                  ? _OwnerTapWrapper(onTap: onEditRequested, child: bubble)
                  : ThoughtBubbleRipple(
                    glowColor: tokens.primary,
                    cloud: cloud,
                    onTap: () {},
                    child: bubble,
                  ),
        ),
      ],
    );
  }
}

class _OwnerTapWrapper extends StatefulWidget {
  const _OwnerTapWrapper({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  State<_OwnerTapWrapper> createState() => _OwnerTapWrapperState();
}

class _OwnerTapWrapperState extends State<_OwnerTapWrapper> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class _TaglineFit {
  const _TaglineFit({
    required this.fontSize,
    required this.maxLines,
    required this.width,
    required this.height,
    required this.horizontalPadding,
  });

  final double fontSize;
  final int maxLines;
  final double width;
  final double height;
  final double horizontalPadding;
}

_TaglineFit _resolveTaglineFit({
  required String text,
  required double availableWidth,
  required double minWidth,
  required double maxBubbleHeight,
  required TextScaler textScaler,
  required bool isPlaceholder,
}) {
  const double oneLinePadding = 24; // 12px each side.
  const double twoLinePadding = 22; // 11px each side.

  TextStyle styleFor(double fontSize) => TextStyle(
    fontSize: fontSize,
    fontWeight: FontWeight.w600,
    fontStyle: isPlaceholder ? FontStyle.italic : FontStyle.normal,
    height: 1.15,
  );

  double oneLineHeight() =>
      math.min(StatusThoughtCloud._oneLineHeight, maxBubbleHeight);
  double twoLineHeight() =>
      math.min(StatusThoughtCloud._twoLineHeight, maxBubbleHeight);

  // Tier 1: does it fit on a single line at a comfortably large size?
  for (final fontSize in const [12.5, 11.5]) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: styleFor(fontSize)),
      maxLines: 1,
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout();
    final naturalWidth = painter.width;
    if (naturalWidth + oneLinePadding <= availableWidth) {
      return _TaglineFit(
        fontSize: fontSize,
        maxLines: 1,
        width: (naturalWidth + oneLinePadding).clamp(minWidth, availableWidth),
        height: oneLineHeight(),
        horizontalPadding: oneLinePadding / 2,
      );
    }
  }

  // Tier 2: let it wrap onto 2 lines, using the full available width.
  for (final fontSize in const [11.5, 10.5]) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: styleFor(fontSize)),
      maxLines: 2,
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout(maxWidth: availableWidth - twoLinePadding);
    if (!painter.didExceedMaxLines) {
      return _TaglineFit(
        fontSize: fontSize,
        maxLines: 2,
        width: availableWidth,
        height: twoLineHeight(),
        horizontalPadding: twoLinePadding / 2,
      );
    }
  }

  // Final safety net: even the smallest tier didn't measure as fitting
  // (e.g. an unusual glyph run) — the FittedBox in `_ThoughtBubbleContent`
  // scales this down further so nothing overflows or clips.
  return _TaglineFit(
    fontSize: 10.5,
    maxLines: 2,
    width: availableWidth,
    height: twoLineHeight(),
    horizontalPadding: twoLinePadding / 2,
  );
}

class _ThoughtBubbleContent extends StatelessWidget {
  const _ThoughtBubbleContent({
    required this.text,
    required this.isPlaceholder,
    required this.fit,
    required this.cloud,
    required this.tokens,
  });

  final String text;
  final bool isPlaceholder;
  final _TaglineFit fit;
  final ThoughtCloudPath cloud;
  final ProfileUiTokens tokens;

  @override
  Widget build(BuildContext context) {
    final bool isDark = tokens.isDark;
    final Color primary = tokens.primary;
    final Color surface = tokens.surface;

    final Color glassTop = Color.alphaBlend(
      primary.withValues(alpha: isDark ? 0.16 : 0.08),
      surface.withValues(alpha: isDark ? 0.82 : 0.92),
    );
    final Color glassBottom = Color.alphaBlend(
      primary.withValues(alpha: isDark ? 0.28 : 0.13),
      surface.withValues(alpha: isDark ? 0.82 : 0.92),
    );

    return RepaintBoundary(
      child: SizedBox(
        width: fit.width,
        height: fit.height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: ThoughtCloudShadowPainter(
                  cloud: cloud,
                  color: primary.withValues(alpha: isDark ? 0.28 : 0.14),
                ),
              ),
            ),
            ClipPath(
              clipper: ThoughtCloudClipper(cloud: cloud),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [glassTop, glassBottom],
                    ),
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: ThoughtBubbleBorderPainter(
                  cloud: cloud,
                  borderColor: primary.withValues(alpha: isDark ? 0.45 : 0.28),
                  highlightColor: Colors.white.withValues(
                    alpha: isDark ? 0.16 : 0.65,
                  ),
                ),
              ),
            ),
            Positioned(
              left: fit.horizontalPadding,
              right: fit.horizontalPadding,
              top: cloud.inset + cloud.crown,
              bottom: cloud.inset + cloud.belly,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    text,
                    maxLines: fit.maxLines,
                    textAlign: TextAlign.center,
                    textScaler: MediaQuery.textScalerOf(
                      context,
                    ).clamp(maxScaleFactor: 1.15),
                    style: TextStyle(
                      fontSize: fit.fontSize,
                      fontWeight: FontWeight.w600,
                      height: 1.15,
                      fontStyle:
                          isPlaceholder ? FontStyle.italic : FontStyle.normal,
                      color: tokens.onSurface.withValues(
                        alpha: isPlaceholder ? 0.55 : 1.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
