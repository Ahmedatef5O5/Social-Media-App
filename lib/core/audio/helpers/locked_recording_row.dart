import 'package:flutter/material.dart';
import 'live_waveform.dart';
import 'pulsing_red_dot.dart';

class LockedRecordingRow extends StatelessWidget {
  final int seconds;
  final List<double> amplitudes;
  final VoidCallback onPause;

  const LockedRecordingRow({
    super.key,
    required this.seconds,
    required this.amplitudes,
    required this.onPause,
  });

  String get _formatted {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
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
        const SizedBox(width: 8),
        Expanded(child: LiveWaveform(amplitudes: amplitudes)),
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onPause,
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.pause_rounded, color: Colors.red, size: 22),
          ),
        ),
      ],
    );
  }
}
