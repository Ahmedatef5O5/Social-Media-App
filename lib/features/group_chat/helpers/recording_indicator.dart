import 'package:flutter/material.dart';

class RecordingIndicator extends StatelessWidget {
  final int seconds;
  const RecordingIndicator({super.key, required this.seconds});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [const Icon(Icons.mic, color: Colors.red), Text('$seconds s')],
    );
  }
}
