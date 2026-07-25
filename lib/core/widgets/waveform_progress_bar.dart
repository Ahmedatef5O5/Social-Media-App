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

class _WaveformProgressBarState extends State<WaveformProgressBar>
    with SingleTickerProviderStateMixin {
  final _boxKey = GlobalKey();
  late final AnimationController _progressCtrl;
  late Animation<double> _progressAnim;
  double _targetProgress = 0;

  double get _rawProgress =>
      widget.duration.inMilliseconds > 0
          ? (widget.position.inMilliseconds / widget.duration.inMilliseconds)
              .clamp(0.0, 1.0)
          : 0.0;

  @override
  void initState() {
    super.initState();
    _targetProgress = _rawProgress;
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _progressAnim = AlwaysStoppedAnimation(_targetProgress);
  }

  @override
  void didUpdateWidget(covariant WaveformProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _rawProgress;
    final isSeek = (next - _targetProgress).abs() > 0.2;
    if ((next - _targetProgress).abs() < 0.0005) return;

    if (isSeek) {
      _targetProgress = next;
      _progressAnim = AlwaysStoppedAnimation(next);
      _progressCtrl.stop();
      setState(() {});
      return;
    }

    _progressAnim = Tween<double>(
      begin: _progressAnim.value,
      end: next,
    ).animate(
      CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOutCubic),
    );
    _targetProgress = next;
    _progressCtrl.forward(from: 0);
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    super.dispose();
  }

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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (d) => _handleSeekAt(d.globalPosition),
      onHorizontalDragUpdate: (d) => _handleSeekAt(d.globalPosition),
      child: SizedBox(
        key: _boxKey,
        height: widget.height,
        child: AnimatedBuilder(
          animation: _progressAnim,
          builder: (context, _) {
            return CustomPaint(
              painter: _WaveformPainter(
                seed: widget.seed,
                activeColor: widget.activeColor,
                inactiveColor: widget.inactiveColor,
                barWidth: widget.barWidth,
                gap: widget.gap,
                progress: _progressAnim.value,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final String seed;
  final Color activeColor;
  final Color inactiveColor;
  final double barWidth;
  final double gap;
  final double progress;

  _WaveformPainter({
    required this.seed,
    required this.activeColor,
    required this.inactiveColor,
    required this.barWidth,
    required this.gap,
    required this.progress,
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
      final segmentLength = 2 + random.nextInt(4);
      final intensity = pow(random.nextDouble(), 1.2).toDouble();
      final baseLevel = 0.2 + (intensity * 0.7);
      for (var j = 0; j < segmentLength && bars.length < count; j++) {
        final pos = j / max(1, segmentLength - 1);
        final window = sin(pos * pi);

        final jitter = (random.nextDouble() - 0.5) * 0.1;
        final value = (baseLevel * (0.5 + 0.5 * window)) + jitter;

        bars.add(value.clamp(0.12, 1.0));
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

    final inactivePaint =
        Paint()
          ..color = inactiveColor
          ..strokeWidth = barWidth
          ..strokeCap = StrokeCap.round;

    final activePaint =
        Paint()
          ..color = activeColor
          ..strokeWidth = barWidth
          ..strokeCap = StrokeCap.round;

    void drawBars(Paint paint) {
      for (var i = 0; i < bars.length; i++) {
        final x = i * (barWidth + gap) + barWidth / 2;
        final barHeight = (bars[i] * size.height).clamp(2.5, size.height);
        final dy = (size.height - barHeight) / 2;
        canvas.drawLine(Offset(x, dy), Offset(x, dy + barHeight), paint);
      }
    }

    drawBars(inactivePaint);

    if (progress > 0) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, size.width * progress, size.height));
      drawBars(activePaint);
      canvas.restore();
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
