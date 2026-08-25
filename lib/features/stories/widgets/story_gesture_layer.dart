import 'package:flutter/material.dart';

class StoryGestureLayer extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final VoidCallback onClose;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressEnd;
  final VoidCallback onNextGroup;
  final VoidCallback onPrevGroup;
  final Widget child;

  const StoryGestureLayer({
    super.key,
    required this.onNext,
    required this.onPrev,
    required this.onClose,
    required this.onLongPressStart,
    required this.onLongPressEnd,
    required this.onNextGroup,
    required this.onPrevGroup,
    required this.child,
  });

  @override
  State<StoryGestureLayer> createState() => _StoryGestureLayerState();
}

class _StoryGestureLayerState extends State<StoryGestureLayer> {
  void _hideKeyboard() {
    if (FocusManager.instance.primaryFocus?.hasFocus ?? false) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) {
        _hideKeyboard();
        final halfWidth = MediaQuery.sizeOf(context).width / 2;
        if (details.globalPosition.dx < halfWidth) {
          widget.onPrev();
        } else {
          widget.onNext();
        }
      },
      onLongPressStart: (_) {
        _hideKeyboard();
        widget.onLongPressStart();
      },
      onLongPressEnd: (_) {
        widget.onLongPressEnd();
      },
      onLongPressCancel: () {
        widget.onLongPressEnd();
      },
      onVerticalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) > 300) {
          _hideKeyboard();
          widget.onClose();
        }
      },
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < -300) {
          _hideKeyboard();
          widget.onNextGroup();
        } else if (velocity > 300) {
          _hideKeyboard();
          widget.onPrevGroup();
        }
      },
      child: widget.child,
    );
  }
}
