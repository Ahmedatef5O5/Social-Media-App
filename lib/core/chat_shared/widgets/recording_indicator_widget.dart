import 'package:flutter/material.dart';

class RecordingIndicatorWidget extends StatefulWidget {
  final double size;
  final Color color;

  const RecordingIndicatorWidget({
    super.key,
    this.size = 14,
    this.color = Colors.red,
  });

  @override
  State<RecordingIndicatorWidget> createState() =>
      _RecordingIndicatorWidgetState();
}

class _RecordingIndicatorWidgetState extends State<RecordingIndicatorWidget>
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
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
        child: Icon(Icons.mic, size: widget.size * 0.62, color: Colors.white),
      ),
    );
  }
}
