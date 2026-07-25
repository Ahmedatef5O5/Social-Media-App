import 'dart:math' as math;
import 'package:flutter/material.dart';

class LiveWaveform extends StatelessWidget {
  final List<double> amplitudes;
  const LiveWaveform({super.key, required this.amplitudes});

  static const double _barWidth = 2.5;
  static const double _barGap = 2;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxBars = math.max(
            1,
            (constraints.maxWidth / (_barWidth + _barGap)).floor(),
          );
          final visible =
              amplitudes.length > maxBars
                  ? amplitudes.sublist(amplitudes.length - maxBars)
                  : amplitudes;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              for (final amp in visible)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Container(
                    width: _barWidth,
                    height: 4 + (amp * 20),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
