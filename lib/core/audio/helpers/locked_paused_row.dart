import 'package:flutter/material.dart';
import '../../widgets/waveform_progress_bar.dart';

class LockedPausedRow extends StatelessWidget {
  final int seconds;
  final bool isPreviewPlaying;
  final Duration previewPosition;
  final Duration previewDuration;
  final String waveformSeed;
  final VoidCallback onTogglePlay;
  final ValueChanged<Duration> onSeek;
  final VoidCallback onResume;

  const LockedPausedRow({
    super.key,
    required this.seconds,
    required this.isPreviewPlaying,
    required this.previewPosition,
    required this.previewDuration,
    required this.waveformSeed,
    required this.onTogglePlay,
    required this.onSeek,
    required this.onResume,
  });

  String get _formatted {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTogglePlay,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              isPreviewPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: primary,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          _formatted,
          style: TextStyle(
            color: primary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: WaveformProgressBar(
            seed: waveformSeed,
            position: previewPosition,
            duration:
                previewDuration > Duration.zero
                    ? previewDuration
                    : Duration(seconds: seconds),
            activeColor: primary,
            onSeek: onSeek,
          ),
        ),
        const SizedBox(width: 6),
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onResume,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.mic_none_rounded, color: primary, size: 16),
                const SizedBox(width: 3),
                Text(
                  'Resume',
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
