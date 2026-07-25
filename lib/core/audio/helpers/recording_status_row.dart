import 'package:flutter/material.dart';
import 'pulsing_red_dot.dart';

class RecordingStatusRow extends StatelessWidget {
  final int seconds;
  final double dragDx;
  final double cancelProgress;

  const RecordingStatusRow({
    super.key,
    required this.seconds,
    required this.dragDx,
    required this.cancelProgress,
  });

  String get _formatted {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final visualOffset = dragDx.clamp(-70.0, 0.0);
    return Row(
      children: [
        const PulsingRedDot(),
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
        Expanded(
          child: Transform.translate(
            offset: Offset(visualOffset, 0),
            child: Opacity(
              opacity: 1 - cancelProgress,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.keyboard_arrow_left_rounded,
                    color: Colors.grey,
                    size: 18,
                  ),
                  Flexible(
                    child: Text(
                      'Slide to cancel',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
