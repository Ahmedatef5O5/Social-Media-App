import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SwipeToReplyWrapper extends StatefulWidget {
  final bool isMe;
  final VoidCallback onReply;
  final Widget child;
  final bool enabled;

  const SwipeToReplyWrapper({
    super.key,
    required this.isMe,
    required this.onReply,
    required this.child,
    this.enabled = true,
  });

  @override
  State<SwipeToReplyWrapper> createState() => _SwipeToReplyWrapperState();
}

class _SwipeToReplyWrapperState extends State<SwipeToReplyWrapper> {
  double _dragOffset = 0;
  bool _triggered = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        if (widget.isMe && details.delta.dx < 0) {
          _dragOffset = (_dragOffset + details.delta.dx).clamp(-60.0, 0.0);
        } else if (!widget.isMe && details.delta.dx > 0) {
          _dragOffset = (_dragOffset + details.delta.dx).clamp(0.0, 60.0);
        }

        if (!_triggered && _dragOffset.abs() >= 50) {
          _triggered = true;
          HapticFeedback.lightImpact();
          widget.onReply();
        }
        setState(() {});
      },
      onHorizontalDragEnd: (_) {
        setState(() {
          _dragOffset = 0;
          _triggered = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        transform: Matrix4.translationValues(_dragOffset, 0, 0),
        child: widget.child,
      ),
    );
  }
}
