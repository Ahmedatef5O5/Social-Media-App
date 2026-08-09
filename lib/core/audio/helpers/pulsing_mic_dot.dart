import 'package:flutter/material.dart';

class PulsingMicDot extends StatefulWidget {
  const PulsingMicDot({super.key});

  @override
  State<PulsingMicDot> createState() => _PulsingMicDotState();
}

class _PulsingMicDotState extends State<PulsingMicDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.35, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: Colors.red.shade600,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.mic, size: 11, color: Colors.white),
      ),
    );
  }
}
