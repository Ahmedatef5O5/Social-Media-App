import 'dart:async';
import 'package:flutter/material.dart';

class AiTypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final bool animate;
  final int charsPerTick;
  final Duration tickInterval;
  final VoidCallback? onDone;
  final TextDirection? textDirection;
  final TextAlign? textAlign;

  const AiTypewriterText({
    super.key,
    required this.text,
    required this.style,
    this.animate = false,
    this.charsPerTick = 3,
    this.tickInterval = const Duration(milliseconds: 18),
    this.onDone,
    this.textDirection,
    this.textAlign,
  });

  @override
  State<AiTypewriterText> createState() => _AiTypewriterTextState();
}

class _AiTypewriterTextState extends State<AiTypewriterText> {
  late int _revealedLength = widget.animate ? 0 : widget.text.length;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.animate && widget.text.isNotEmpty) {
      _timer = Timer.periodic(widget.tickInterval, _onTick);
    }
  }

  void _onTick(Timer timer) {
    if (!mounted) {
      timer.cancel();
      return;
    }
    final next = _revealedLength + widget.charsPerTick;
    if (next >= widget.text.length) {
      timer.cancel();
      setState(() => _revealedLength = widget.text.length);
      widget.onDone?.call();
    } else {
      setState(() => _revealedLength = next);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safeLength = _revealedLength.clamp(0, widget.text.length);
    return Text(
      widget.text.substring(0, safeLength),
      style: widget.style,
      textDirection: widget.textDirection,
      textAlign: widget.textAlign,
    );
  }
}
