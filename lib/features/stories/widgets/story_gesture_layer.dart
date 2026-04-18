import 'package:flutter/material.dart';

class StoryGestureLayer extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final VoidCallback onClose;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressEnd;

  const StoryGestureLayer({
    super.key,
    required this.onNext,
    required this.onPrev,
    required this.onClose,
    required this.onLongPressStart,
    required this.onLongPressEnd,
  });

  @override
  State<StoryGestureLayer> createState() => _StoryGestureLayerState();
}

class _StoryGestureLayerState extends State<StoryGestureLayer> {
  double x = 0, y = 0, t = 0;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) {
        x = e.position.dx;
        y = e.position.dy;
        t = e.timeStamp.inMilliseconds.toDouble();
      },
      onPointerUp: (e) {
        final dx = e.position.dx - x;
        final dy = e.position.dy - y;
        final dt = e.timeStamp.inMilliseconds - t;

        if (dt > 300 && dx.abs() < 10 && dy.abs() < 10) {
          widget.onLongPressEnd();
          return;
        }

        if (dy.abs() > dx.abs() && dy.abs() > 50) {
          widget.onClose();
          return;
        }

        if (dx.abs() > 50) {
          dx < 0 ? widget.onNext() : widget.onPrev();
          return;
        }

        final half = MediaQuery.of(context).size.width / 2;
        e.position.dx < half ? widget.onPrev() : widget.onNext();
      },
      onPointerMove: (e) {
        final dx = e.position.dx - x;
        final dy = e.position.dy - y;
        final dt = e.timeStamp.inMilliseconds - t;

        if (dt > 300 && dx.abs() < 10 && dy.abs() < 10) {
          widget.onLongPressStart();
        }
      },
    );
  }
}
