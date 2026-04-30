import 'package:flutter/material.dart';
import 'package:social_media_app/features/group_chat/helpers/pulsing_dot.dart';

class RecordingIndicator extends StatelessWidget {
  final int seconds;
  const RecordingIndicator({super.key, required this.seconds});

  String get _formatted {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const PulsingDot(),
          const SizedBox(width: 8),
          Text(
            _formatted,
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w600,
              fontSize: 15,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 8),
          const Flexible(
            child: Text(
              'Recording...',
              style: TextStyle(color: Colors.red, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
