import 'dart:math';
import 'package:flutter/material.dart';

class WaveformProgressBar extends StatefulWidget {
  final String seed;
  final Duration position;
  final Duration duration;
  final Color activeColor;
  final Color inactiveColor;
  final ValueChanged<Duration>? onSeek;
  final double height;
  final double barWidth;
  final double gap;

  const WaveformProgressBar({
    super.key,
    required this.seed,
    required this.position,
    required this.duration,
    required this.activeColor,
    this.inactiveColor = const Color(0x33000000),
    this.onSeek,
    this.height = 24,
    this.barWidth = 3.2,
    this.gap = 2.2,
  });

  @override
  State<WaveformProgressBar> createState() => _WaveformProgressBarState();
}

class _WaveformProgressBarState extends State<WaveformProgressBar> {
  final _boxKey = GlobalKey();

  void _handleSeekAt(Offset globalPosition) {
    if (widget.onSeek == null || widget.duration <= Duration.zero) return;
    final box = _boxKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final local = box.globalToLocal(globalPosition);
    final ratio = (local.dx / box.size.width).clamp(0.0, 1.0);
    widget.onSeek!(widget.duration * ratio);
  }

  @override
  Widget build(BuildContext context) {
    final progress =
        widget.duration.inMilliseconds > 0
            ? (widget.position.inMilliseconds / widget.duration.inMilliseconds)
                .clamp(0.0, 1.0)
            : 0.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (d) => _handleSeekAt(d.globalPosition),
      onHorizontalDragUpdate: (d) => _handleSeekAt(d.globalPosition),
      child: SizedBox(
        key: _boxKey,
        height: widget.height,
        child: CustomPaint(
          size: Size.infinite,
          painter: _WaveformPainter(
            seed: widget.seed,
            progress: progress,
            activeColor: widget.activeColor,
            inactiveColor: widget.inactiveColor,
            barWidth: widget.barWidth,
            gap: widget.gap,
          ),
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final String seed;
  final double progress;
  final Color activeColor;
  final Color inactiveColor;
  final double barWidth;
  final double gap;

  _WaveformPainter({
    required this.seed,
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
    required this.barWidth,
    required this.gap,
  });

  static final Map<String, List<double>> _barsCache = {};

  List<double> _barsFor(int count) {
    if (count <= 0) return const [];
    final cacheKey = '$seed-$count';
    final cached = _barsCache[cacheKey];
    if (cached != null) return cached;

    final random = Random(seed.hashCode);
    final bars = <double>[];

    while (bars.length < count) {
      final segmentLength = 2 + random.nextInt(5); // 2–6 bars per burst
      final baseLevel = 0.18 + random.nextDouble() * 0.82; // burst intensity
      for (var j = 0; j < segmentLength && bars.length < count; j++) {
        final jitter = (random.nextDouble() - 0.5) * 0.2;
        bars.add((baseLevel + jitter).clamp(0.08, 1.0));
      }
    }

    _barsCache[cacheKey] = bars;
    return bars;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final count = max(1, (size.width / (barWidth + gap)).floor());
    final bars = _barsFor(count);
    if (bars.isEmpty) return;

    final activeBars = (bars.length * progress).round();

    final activePaint =
        Paint()
          ..color = activeColor
          ..strokeWidth = barWidth
          ..strokeCap = StrokeCap.round;
    final inactivePaint =
        Paint()
          ..color = inactiveColor
          ..strokeWidth = barWidth
          ..strokeCap = StrokeCap.round;

    for (var i = 0; i < bars.length; i++) {
      final x = i * (barWidth + gap) + barWidth / 2;
      final barHeight = (bars[i] * size.height).clamp(2.5, size.height);
      final dy = (size.height - barHeight) / 2;
      canvas.drawLine(
        Offset(x, dy),
        Offset(x, dy + barHeight),
        i < activeBars ? activePaint : inactivePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.seed != seed ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor ||
        oldDelegate.barWidth != barWidth ||
        oldDelegate.gap != gap;
  }
}
