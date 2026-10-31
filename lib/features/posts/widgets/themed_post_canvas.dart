import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../../core/design/tokens/typography.dart';
import '../../../core/helpers/emoji_helper.dart';
import '../models/post_theme_model.dart';

/// Gradient canvas with optional user-selected ambient motifs (emojis/icons).
/// Shared by `PostThemesView`, `CreatePostView`, and `ThemedPostCard`.
class ThemedPostCanvas extends StatelessWidget {
  final PostBackgroundThemeModel theme;
  final Widget child;
  final List<String> motifs;
  final int seed;
  final double minHeight;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  /// Extra bottom height kept free of motifs (e.g. floating action pills in
  /// `CreatePostView`).
  final double bottomReservedHeight;

  const ThemedPostCanvas({
    super.key,
    required this.theme,
    required this.child,
    this.motifs = const [],
    this.seed = 0,
    this.minHeight = 220,
    this.borderRadius = 20,
    this.padding,
    this.bottomReservedHeight = 0,
  });

  /// Horizontal padding adapts automatically: roomy ambient margin when motifs
  /// are active so icons always have safe perimeter space, wider text area
  /// when relying on pure background color.
  static EdgeInsets defaultPaddingFor({required bool hasMotifs}) {
    return hasMotifs
        ? const EdgeInsets.symmetric(horizontal: 50, vertical: 48)
        : const EdgeInsets.symmetric(horizontal: 30, vertical: 36);
  }

  /// Scales typography smoothly from punchy one-liners to 8+ line stories.
  static double fontSizeFor(String text) {
    final length = text.trim().length;
    if (length <= 40) return 26;
    if (length <= 110) return 22;
    if (length <= 220) return 19;
    return 16.5;
  }

  /// Bold, centered post style with a soft shadow for legibility.
  static TextStyle textStyleFor(
    PostBackgroundThemeModel theme, {
    required double fontSize,
    TextStyle? base,
  }) {
    return (base ?? const TextStyle()).copyWith(
      color: theme.textColor,
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      height: 1.35,
      shadows:
          theme.isLightText
              ? const [
                Shadow(
                  color: Color(0x40000000),
                  blurRadius: 6,
                  offset: Offset(0, 1),
                ),
              ]
              : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectivePadding =
        padding ?? defaultPaddingFor(hasMotifs: motifs.isNotEmpty);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.previewColor,
          gradient: theme.gradient,
        ),
        child: _AmbientMotifStage(
          theme: theme,
          motifs: motifs,
          seed: seed,
          minHeight: minHeight,
          padding: effectivePadding,
          textDirection: Directionality.of(context),
          bottomReservedHeight: bottomReservedHeight,
          child: child,
        ),
      ),
    );
  }
}

class _PlacedMotif {
  final String token;
  final Offset center;
  final double size;
  final double rotation;
  final int tierIndex;

  const _PlacedMotif({
    required this.token,
    required this.center,
    required this.size,
    required this.rotation,
    required this.tierIndex,
  });
}

class _AmbientMotifStage extends SingleChildRenderObjectWidget {
  final PostBackgroundThemeModel theme;
  final List<String> motifs;
  final int seed;
  final double minHeight;
  final EdgeInsetsGeometry padding;
  final TextDirection textDirection;
  final double bottomReservedHeight;

  const _AmbientMotifStage({
    required this.theme,
    required this.motifs,
    required this.seed,
    required this.minHeight,
    required this.padding,
    required this.textDirection,
    required this.bottomReservedHeight,
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderAmbientMotifStage(
      theme: theme,
      motifs: motifs,
      seed: seed,
      minHeight: minHeight,
      padding: padding,
      textDirection: textDirection,
      bottomReservedHeight: bottomReservedHeight,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderAmbientMotifStage renderObject,
  ) {
    renderObject
      ..theme = theme
      ..motifs = motifs
      ..seed = seed
      ..minHeight = minHeight
      ..padding = padding
      ..textDirection = textDirection
      ..bottomReservedHeight = bottomReservedHeight;
  }
}

class _RenderAmbientMotifStage extends RenderShiftedBox {
  PostBackgroundThemeModel _theme;
  List<String> _motifs;
  int _seed;
  double _minHeight;
  EdgeInsetsGeometry _padding;
  TextDirection _textDirection;
  double _bottomReservedHeight;

  Size? _cachedCanvasSize;
  Rect? _cachedTextRect;
  List<String>? _cachedMotifs;
  int? _cachedSeed;
  double? _cachedBottomReserved;
  List<_PlacedMotif> _placedMotifs = const [];

  _RenderAmbientMotifStage({
    required PostBackgroundThemeModel theme,
    required List<String> motifs,
    required int seed,
    required double minHeight,
    required EdgeInsetsGeometry padding,
    required TextDirection textDirection,
    required double bottomReservedHeight,
  }) : _theme = theme,
       _motifs = motifs,
       _seed = seed,
       _minHeight = minHeight,
       _padding = padding,
       _textDirection = textDirection,
       _bottomReservedHeight = bottomReservedHeight,
       super(null);

  set theme(PostBackgroundThemeModel value) {
    if (_theme == value) return;
    _theme = value;
    markNeedsPaint();
  }

  set motifs(List<String> value) {
    if (listEquals(_motifs, value)) return;
    _motifs = value;
    _invalidatePlacements();
    markNeedsLayout();
  }

  set seed(int value) {
    if (_seed == value) return;
    _seed = value;
    _invalidatePlacements();
    markNeedsPaint();
  }

  set minHeight(double value) {
    if (_minHeight == value) return;
    _minHeight = value;
    markNeedsLayout();
  }

  set padding(EdgeInsetsGeometry value) {
    if (_padding == value) return;
    _padding = value;
    markNeedsLayout();
  }

  set textDirection(TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    markNeedsLayout();
  }

  set bottomReservedHeight(double value) {
    if (_bottomReservedHeight == value) return;
    _bottomReservedHeight = value;
    _invalidatePlacements();
    markNeedsPaint();
  }

  void _invalidatePlacements() {
    _cachedCanvasSize = null;
    _cachedTextRect = null;
  }

  @override
  void performLayout() {
    final resolvedPadding = _padding.resolve(_textDirection);
    final double maxWidth =
        constraints.hasBoundedWidth
            ? constraints.maxWidth
            : resolvedPadding.horizontal + 280.0;

    if (child == null) {
      size = constraints.constrain(Size(maxWidth, _minHeight));
      return;
    }

    final double innerMaxWidth = math.max(
      0.0,
      maxWidth - resolvedPadding.horizontal,
    );
    child!.layout(
      BoxConstraints(maxWidth: innerMaxWidth),
      parentUsesSize: true,
    );

    final Size childSize = child!.size;
    final double desiredHeight = math.max(
      _minHeight,
      childSize.height + resolvedPadding.vertical,
    );
    size = constraints.constrain(Size(maxWidth, desiredHeight));

    final double freeWidth = math.max(
      0.0,
      size.width - resolvedPadding.horizontal - childSize.width,
    );
    final double freeHeight = math.max(
      0.0,
      size.height - resolvedPadding.vertical - childSize.height,
    );

    final boxParentData = child!.parentData! as BoxParentData;
    boxParentData.offset = Offset(
      resolvedPadding.left + freeWidth / 2.0,
      resolvedPadding.top + freeHeight / 2.0,
    );
  }

  List<_PlacedMotif> _ensurePlacements(Rect textRect) {
    if (_motifs.isEmpty) return const [];

    if (_cachedCanvasSize == size &&
        _cachedTextRect == textRect &&
        _cachedSeed == _seed &&
        _cachedBottomReserved == _bottomReservedHeight &&
        _cachedMotifs != null &&
        listEquals(_cachedMotifs, _motifs)) {
      return _placedMotifs;
    }

    _cachedCanvasSize = size;
    _cachedTextRect = textRect;
    _cachedSeed = _seed;
    _cachedBottomReserved = _bottomReservedHeight;
    _cachedMotifs = List<String>.from(_motifs);

    final rng = math.Random(_seed == 0 ? 7919 : _seed);

    // Randomize count per post so every post feels organically unique.
    final int baseCount = switch (_motifs.length) {
      1 => 5 + rng.nextInt(5), // 5..9
      2 => 6 + rng.nextInt(6), // 6..11
      _ => 7 + rng.nextInt(6), // 7..12
    };
    final int heightBonus =
        size.height > 320 ? ((size.height - 320) / 150).floor().clamp(0, 4) : 0;
    final int targetCount = baseCount + heightBonus;

    final double edgePad = 7.0;
    final double textClearance = 15.0;
    final double usableBottom = math.max(
      0.0,
      size.height - _bottomReservedHeight,
    );
    final Offset canvasCenter = Offset(size.width / 2.0, usableBottom / 2.0);
    final double maxCornerDist = math.max(
      1.0,
      (Offset.zero - canvasCenter).distance,
    );

    final results = <_PlacedMotif>[];
    int attempts = 0;
    const int maxAttempts = 260;

    while (results.length < targetCount && attempts < maxAttempts) {
      attempts++;

      final double motifSize = 20.0 + rng.nextDouble() * 8.0; // 20..28 px
      final double half = motifSize * 0.56;

      final double minX = edgePad + half;
      final double maxX = size.width - edgePad - half;
      final double minY = edgePad + half;
      final double maxY = usableBottom - edgePad - half;
      if (maxX <= minX || maxY <= minY) break;

      final candidate = Offset(
        minX + rng.nextDouble() * (maxX - minX),
        minY + rng.nextDouble() * (maxY - minY),
      );

      // Strict rounded-halo exclusion around the actual text bounding box:
      // guarantees zero overlap, touching, or crowding near the written words.
      final RRect textExclusionHalo = RRect.fromRectAndRadius(
        textRect.inflate(textClearance + half),
        Radius.circular(22.0 + half),
      );
      if (textExclusionHalo.contains(candidate)) continue;

      // Minimum Poisson-disc spacing between motifs so icons never overlap.
      bool collidesWithExisting = false;
      for (final other in results) {
        final double minSpacing = half + (other.size * 0.56) + 16.0;
        if ((candidate - other.center).distance < minSpacing) {
          collidesWithExisting = true;
          break;
        }
      }
      if (collidesWithExisting) continue;

      // Guarantee every user-picked motif appears at least once before random
      // sampling fills the remaining slots.
      final String token =
          results.length < _motifs.length
              ? _motifs[results.length]
              : _motifs[rng.nextInt(_motifs.length)];

      final double rotation = (rng.nextDouble() - 0.5) * 0.45;

      // Distance from candidate to the nearest edge of the text rectangle:
      final double dxToText = math.max(
        0.0,
        math.max(textRect.left - candidate.dx, candidate.dx - textRect.right),
      );
      final double dyToText = math.max(
        0.0,
        math.max(textRect.top - candidate.dy, candidate.dy - textRect.bottom),
      );
      final double distToText = math.sqrt(
        dxToText * dxToText + dyToText * dyToText,
      );

      // Distance-to-text scaling: close to text gets tier 0 (70%),
      // rising to 85%-90% towards outer perimeter and edges.
      final double maxReach = math.max(
        1.0,
        math.max(size.width, size.height) * 0.42,
      );
      final double distRatio = (distToText / maxReach).clamp(0.0, 1.0);
      final double radialNorm =
          ((candidate - canvasCenter).distance / maxCornerDist).clamp(0.0, 1.0);
      final double edgeScore = (distRatio * 0.75 + radialNorm * 0.25).clamp(
        0.0,
        0.999,
      );
      final int tierIndex = (edgeScore * 4).floor(); // 0..3

      results.add(
        _PlacedMotif(
          token: token,
          center: candidate,
          size: motifSize,
          rotation: rotation,
          tierIndex: tierIndex,
        ),
      );
    }

    _placedMotifs = results;
    return _placedMotifs;
  }

  /// Scale-invariant alpha matrix: preserves 100% of the emoji's native vibrant
  /// colors (yellow, cyan, red, etc.) without tinting or hue-shifting, while
  /// scaling alpha smoothly to [opacity].
  static List<double> _emojiAlphaMatrix(double opacity) {
    return <double>[
      1.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      1.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      1.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      opacity,
      0.0,
    ];
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) return;

    final boxParentData = child!.parentData! as BoxParentData;
    final Rect localTextRect = boxParentData.offset & child!.size;
    final placements = _ensurePlacements(localTextRect);

    if (placements.isNotEmpty) {
      final Canvas canvas = context.canvas;
      canvas.save();
      canvas.translate(offset.dx, offset.dy);
      canvas.clipRect(Offset.zero & size);

      // Graduated opacity: 70% near text perimeter, rising to 85%-90% at edges.
      const List<double> opacityTiers = [0.70, 0.77, 0.84, 0.90];

      // 1) Vector icons: rendered directly with theme-adapted alpha tinting
      // (zero saveLayer overhead).
      for (final item in placements) {
        final IconData? iconData = PostThemePresetIcons.resolveIcon(item.token);
        if (iconData == null) continue;
        final double alpha = opacityTiers[item.tierIndex];
        _paintGlyph(
          canvas: canvas,
          item: item,
          text: String.fromCharCode(iconData.codePoint),
          style: TextStyle(
            inherit: false,
            fontSize: item.size,
            fontFamily: iconData.fontFamily,
            package: iconData.fontPackage,
            color: _theme.motifTintColor.withValues(alpha: alpha),
          ),
        );
      }

      // 2) Color emojis: preserves original vibrant multi-color pixels with
      // pure alpha modulation per depth tier (no tinting or hue-loss).
      for (int tier = 0; tier < opacityTiers.length; tier++) {
        bool layerOpened = false;
        for (final item in placements) {
          if (item.tierIndex != tier ||
              PostThemePresetIcons.isIconToken(item.token)) {
            continue;
          }
          if (!layerOpened) {
            layerOpened = true;
            canvas.saveLayer(
              Offset.zero & size,
              Paint()
                ..colorFilter = ColorFilter.matrix(
                  _emojiAlphaMatrix(opacityTiers[tier]),
                ),
            );
          }
          _paintGlyph(
            canvas: canvas,
            item: item,
            text: EmojiHelper.normalize(item.token),
            style: const TextStyle(
              fontFamily: null,
              fontFamilyFallback: AppTypography.emojiFontFallback,
            ).copyWith(fontSize: item.size),
          );
        }
        if (layerOpened) {
          canvas.restore();
        }
      }

      canvas.restore();
    }

    // Paint the foreground text widget crisply on top at 100% prominence.
    context.paintChild(child!, offset + boxParentData.offset);
  }

  void _paintGlyph({
    required Canvas canvas,
    required _PlacedMotif item,
    required String text,
    required TextStyle style,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(item.center.dx, item.center.dy);
    canvas.rotate(item.rotation);
    tp.paint(canvas, Offset(-tp.width / 2.0, -tp.height / 2.0));
    canvas.restore();
  }
}
