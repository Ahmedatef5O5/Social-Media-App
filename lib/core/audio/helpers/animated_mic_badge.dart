import 'dart:math' as math;
import 'package:flutter/material.dart';

const Color _micAccentRed = Color(0xFFE53935);
const Color _micPaleRed = Color(0xFFFFCDD2);

class AnimatedMicBadge extends StatefulWidget {
  final bool isPlaying;
  final double size;

  const AnimatedMicBadge({super.key, required this.isPlaying, this.size = 30});

  @override
  State<AnimatedMicBadge> createState() => _AnimatedMicBadgeState();
}

class _AnimatedMicBadgeState extends State<AnimatedMicBadge>
    with SingleTickerProviderStateMixin {
  final math.Random _random = math.Random();

  late final AnimationController _levelController;
  late Animation<double> _levelAnim;
  double _level = 0.15;

  Duration _randomBeatDuration() =>
      Duration(milliseconds: 140 + _random.nextInt(240));

  double _randomTarget() => 0.15 + _random.nextDouble() * 0.75;

  void _onBeatStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed && widget.isPlaying) {
      _queueNextBeat();
    }
  }

  void _queueNextBeat() {
    final next = _randomTarget();
    _levelAnim = Tween<double>(begin: _level, end: next).animate(
      CurvedAnimation(parent: _levelController, curve: Curves.easeInOut),
    )..addListener(() => setState(() => _level = _levelAnim.value));
    _levelController
      ..duration = _randomBeatDuration()
      ..forward(from: 0);
  }

  @override
  void initState() {
    super.initState();
    _levelController = AnimationController(
      vsync: this,
      duration: _randomBeatDuration(),
    )..addStatusListener(_onBeatStatusChanged);
    _levelAnim = AlwaysStoppedAnimation(_level);

    if (widget.isPlaying) _queueNextBeat();
  }

  @override
  void didUpdateWidget(covariant AnimatedMicBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPlaying == widget.isPlaying) return;

    if (widget.isPlaying) {
      _queueNextBeat();
    } else {
      _levelAnim = Tween<double>(begin: _level, end: 0.12).animate(
        CurvedAnimation(parent: _levelController, curve: Curves.easeOut),
      )..addListener(() => setState(() => _level = _levelAnim.value));
      _levelController
        ..duration = const Duration(milliseconds: 280)
        ..forward(from: 0);
    }
  }

  @override
  void dispose() {
    _levelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      padding: EdgeInsets.all(widget.size * 0.185),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 1)),
        ],
      ),
      child: _LiquidMicIcon(level: _level),
    );
  }
}

class _LiquidMicIcon extends StatelessWidget {
  final double level;
  const _LiquidMicIcon({required this.level});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final iconSize = constraints.biggest.shortestSide;
        return Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.mic_rounded, color: _micPaleRed, size: iconSize),
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) {
                final clamped = level.clamp(0.0, 1.0);
                return LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: const [
                    _micAccentRed,
                    _micAccentRed,
                    Colors.transparent,
                    Colors.transparent,
                  ],
                  stops: [0.0, clamped, clamped, 1.0],
                ).createShader(bounds);
              },
              child: Icon(
                Icons.mic_rounded,
                color: Colors.white,
                size: iconSize,
              ),
            ),
          ],
        );
      },
    );
  }
}
