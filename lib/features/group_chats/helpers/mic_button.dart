import 'package:flutter/material.dart';

class MicButton extends StatelessWidget {
  final bool isRecording;
  final Color primary;
  final Future<void> Function() onStart;
  final Future<void> Function() onEnd;

  const MicButton({
    super.key,
    required this.isRecording,
    required this.primary,
    required this.onStart,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onLongPressStart: (_) => onStart(),
        onLongPressEnd: (_) => onEnd(),
        child: Icon(
          isRecording ? Icons.mic : Icons.mic_none,
          color: isRecording ? Colors.red : primary,
        ),
      );
}