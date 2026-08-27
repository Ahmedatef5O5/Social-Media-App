import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/design/tokens/typography.dart';

class ReactionFountainWidget extends StatefulWidget {
  final List<String> reactionEmojis;
  final int multiplier;
  final int maxParticles;
  final double rightMargin;
  final double bottomMargin;

  const ReactionFountainWidget({
    super.key,
    required this.reactionEmojis,
    this.multiplier = 4,
    this.maxParticles = 32,
    this.rightMargin = 28,
    this.bottomMargin = 110,
  });

  @override
  State<ReactionFountainWidget> createState() => _ReactionFountainWidgetState();
}

class _FountainParticle {
  final String emoji;
  final double startFraction;
  final double durationFraction;
  final double spawnXJitter;
  final double wobbleAmplitude;
  final double wobbleFrequency;
  final double wobbleDirection;
  final double travelFraction;
  final double sizeScale;
  final double rotationAmplitude;

  _FountainParticle({
    required this.emoji,
    required this.startFraction,
    required this.durationFraction,
    required this.spawnXJitter,
    required this.wobbleAmplitude,
    required this.wobbleFrequency,
    required this.wobbleDirection,
    required this.travelFraction,
    required this.sizeScale,
    required this.rotationAmplitude,
  });
}

class _ReactionFountainWidgetState extends State<ReactionFountainWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  List<_FountainParticle> _particles = [];

  static const int _riseMs = 1400;
  static const int _maxStartDelayMs = 1600;
  static const double _fadeStart = 0.62;

  int _playedCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _playBurstFor(widget.reactionEmojis, widget.reactionEmojis.length);
  }

  void _playBurstFor(List<String> newReactions, int newTotalPlayedCount) {
    _playedCount = newTotalPlayedCount;

    if (newReactions.isEmpty) {
      setState(() => _particles = []);
      return;
    }

    final random = math.Random();
    final expanded = <String>[];
    for (final emoji in newReactions) {
      for (var i = 0; i < widget.multiplier; i++) {
        expanded.add(emoji);
      }
    }

    final capped =
        expanded.length > widget.maxParticles
            ? (expanded..shuffle(random)).take(widget.maxParticles).toList()
            : expanded;

    const totalMs = _riseMs + _maxStartDelayMs;

    final particles =
        capped.map((emoji) {
          final startMs = random.nextDouble() * _maxStartDelayMs;
          return _FountainParticle(
            emoji: emoji,
            startFraction: startMs / totalMs,
            durationFraction: _riseMs / totalMs,
            spawnXJitter: (random.nextDouble() - 0.5) * 50,
            wobbleAmplitude: 14 + random.nextDouble() * 18,
            wobbleFrequency: 1.0 + random.nextDouble() * 1.2,
            wobbleDirection: random.nextBool() ? 1.0 : -1.0,
            travelFraction: 0.25 + random.nextDouble() * (1 / 3 - 0.25),
            sizeScale: 0.8 + random.nextDouble() * 0.5,
            rotationAmplitude: (random.nextDouble() - 0.5) * 0.35,
          );
        }).toList();

    setState(() => _particles = particles);

    _controller
      ..duration = const Duration(milliseconds: totalMs)
      ..reset()
      ..forward();
  }

  @override
  void didUpdateWidget(covariant ReactionFountainWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reactionEmojis.length > _playedCount) {
      final newOnes = widget.reactionEmojis.sublist(_playedCount);
      _playBurstFor(newOnes, widget.reactionEmojis.length);
    } else if (widget.reactionEmojis.length < _playedCount) {
      _playedCount = widget.reactionEmojis.length;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_particles.isEmpty) return const SizedBox.shrink();

    final screenHeight = MediaQuery.sizeOf(context).height;

    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Stack(
              children: _particles
                  .map((p) => _buildParticle(p, screenHeight))
                  .toList(growable: false),
            );
          },
        ),
      ),
    );
  }

  Widget _buildParticle(_FountainParticle p, double screenHeight) {
    final v = _controller.value;

    if (v < p.startFraction || v > p.startFraction + p.durationFraction) {
      return const SizedBox.shrink();
    }

    final t = ((v - p.startFraction) / p.durationFraction).clamp(0.0, 1.0);
    final easedT = Curves.easeOut.transform(t);

    final travelDistance = screenHeight * p.travelFraction;
    final riseY = easedT * travelDistance;

    final wobbleX =
        p.wobbleDirection *
        p.wobbleAmplitude *
        math.sin(t * 2 * math.pi * p.wobbleFrequency);

    double opacity;
    if (t < _fadeStart) {
      opacity = 1.0;
    } else {
      opacity = (1.0 - (t - _fadeStart) / (1.0 - _fadeStart)).clamp(0.0, 1.0);
    }

    final popT = (t / 0.12).clamp(0.0, 1.0);
    final popScale = Curves.elasticOut.transform(popT);
    final finalScale = p.sizeScale * popScale;

    final rotation = p.rotationAmplitude * math.sin(t * 2 * math.pi);

    return Positioned(
      right: widget.rightMargin + p.spawnXJitter + wobbleX,
      bottom: widget.bottomMargin + riseY,
      child: Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: rotation,
          child: Transform.scale(
            scale: finalScale,
            child: Text(
              p.emoji,
              style: TextStyle(
                fontSize: 26,
                decoration: TextDecoration.none,
                inherit: false,
                fontWeight: FontWeight.normal,
                fontFamilyFallback: AppTypography.emojiFontFallback,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
