import 'package:flutter/material.dart';
import 'dart:async';

class AnimatedActivityText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final int maxLines;
  final TextOverflow overflow;

  const AnimatedActivityText({
    super.key,
    required this.text,
    this.style,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  });

  @override
  State<AnimatedActivityText> createState() => _AnimatedActivityTextState();
}

class _AnimatedActivityTextState extends State<AnimatedActivityText> {
  int _dotCount = 1;
  bool _isAscending = true;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 350), (timer) {
      if (mounted) {
        setState(() {
          if (_isAscending) {
            _dotCount++;
            if (_dotCount >= 3) _isAscending = false;
          } else {
            _dotCount--;
            if (_dotCount <= 1) _isAscending = true;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String baseText = widget.text;
    bool isAnimated = false;

    if (baseText.toLowerCase().contains('typing') ||
        baseText.toLowerCase().contains('recording')) {
      isAnimated = true;
      baseText = baseText.replaceAll(RegExp(r'\.+$'), '');
    }

    if (!isAnimated) {
      return Text(
        baseText,
        style: widget.style,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
      );
    }

    String displayText = '$baseText\u00A0${'.' * _dotCount}';
    String maxSpaceText = '$baseText\u00A0...';

    return Stack(
      alignment: AlignmentDirectional.centerStart,
      children: [
        Opacity(
          opacity: 0.0,
          child: Text(
            maxSpaceText,
            style: widget.style,
            maxLines: widget.maxLines,
            overflow: widget.overflow,
          ),
        ),
        PositionedDirectional(
          start: 0,
          top: 0,
          bottom: 0,
          child: Text(
            displayText,
            style: widget.style,
            maxLines: widget.maxLines,
            overflow: widget.overflow,
          ),
        ),
      ],
    );
  }
}
