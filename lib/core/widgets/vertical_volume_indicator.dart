import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class VerticalVolumeIndicator extends StatelessWidget {
  final ValueListenable<double> volume; // 0..100
  final Animation<double> opacity;

  const VerticalVolumeIndicator({
    super.key,
    required this.volume,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: opacity,
      child: IgnorePointer(
        child: ValueListenableBuilder<double>(
          valueListenable: volume,
          builder: (context, value, _) {
            return Container(
              width: 34,
              height: 160,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Column(
                children: [
                  Icon(
                    value <= 0
                        ? Icons.volume_off_rounded
                        : value < 50
                        ? Icons.volume_down_rounded
                        : Icons.volume_up_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: (value / 100).clamp(0.0, 1.0),
                        widthFactor: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${value.round()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
