import 'dart:async';
import 'package:flutter/material.dart';

class NewPostsPill extends StatefulWidget {
  final int count;
  final VoidCallback onTap;

  final bool hideForOverlap;

  const NewPostsPill({
    super.key,
    required this.count,
    required this.onTap,
    this.hideForOverlap = false,
  });

  @override
  State<NewPostsPill> createState() => _NewPostsPillState();
}

class _NewPostsPillState extends State<NewPostsPill> {
  int _displayCount = 0;

  bool _dismissed = false;

  Timer? _autoHideTimer;
  double _dragDx = 0;

  @override
  void initState() {
    super.initState();
    _displayCount = widget.count;
    if (widget.count > 0) _restartAutoHideTimer();
  }

  @override
  void didUpdateWidget(covariant NewPostsPill oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.count > 0) {
      _displayCount = widget.count;
    }

    if (widget.count > oldWidget.count) {
      _dismissed = false;
      _restartAutoHideTimer();
    } else if (widget.count == 0) {
      _autoHideTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _autoHideTimer?.cancel();
    super.dispose();
  }

  void _restartAutoHideTimer() {
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) setState(() => _dismissed = true);
    });
  }

  void _handleSwipeDismiss() {
    _autoHideTimer?.cancel();
    setState(() {
      _dismissed = true;
      _dragDx = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isVisible =
        widget.count > 0 && !_dismissed && !widget.hideForOverlap;

    return IgnorePointer(
      ignoring: !isVisible,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isVisible ? 1 : 0,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          offset: isVisible ? Offset.zero : const Offset(0, -0.6),
          child: GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() => _dragDx += details.delta.dx);
            },
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (_dragDx.abs() > 60 || velocity.abs() > 600) {
                _handleSwipeDismiss();
              } else {
                setState(() => _dragDx = 0);
              }
            },
            child: Transform.translate(
              offset: Offset(_dragDx, 0),
              child: Material(
                color: Theme.of(context).primaryColor,
                elevation: 4,
                borderRadius: BorderRadius.circular(30),
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(30),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.arrow_upward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$_displayCount New ${_displayCount == 1 ? 'Post' : 'Posts'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
