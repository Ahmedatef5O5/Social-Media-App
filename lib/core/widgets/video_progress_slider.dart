import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoProgressSlider extends StatelessWidget {
  final VideoPlayerController controller;
  final double trackHeight;
  final double thumbSize;
  final bool showPosition;
  final TextStyle? positionStyle;

  const VideoProgressSlider({
    super.key,
    required this.controller,
    this.trackHeight = 2.8,
    this.thumbSize = 10,
    this.showPosition = false,
    this.positionStyle,
  });

  String _formatDuration(Duration d) {
    if (d.isNegative) d = Duration.zero;
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$mm:$ss';
    }
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final duration = value.duration;
        final position = value.position;
        final hasDuration = duration > Duration.zero;
        final progress =
            hasDuration
                ? (position.inMilliseconds / duration.inMilliseconds).clamp(
                  0.0,
                  1.0,
                )
                : 0.0;

        final progressBar = LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            void seekToLocalDx(double dx) {
              if (!hasDuration) return;
              final ratio = (dx / width).clamp(0.0, 1.0);
              controller.seekTo(duration * ratio);
            }

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => seekToLocalDx(d.localPosition.dx),
              onHorizontalDragUpdate: (d) => seekToLocalDx(d.localPosition.dx),
              child: SizedBox(
                height: thumbSize + 4,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: trackHeight,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(trackHeight),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: trackHeight,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(trackHeight),
                        ),
                      ),
                    ),
                    Positioned(
                      left: ((width - thumbSize) * progress).clamp(
                        0.0,
                        width - thumbSize,
                      ),
                      child: Container(
                        width: thumbSize,
                        height: thumbSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).primaryColor,
                          boxShadow: const [
                            BoxShadow(color: Colors.black45, blurRadius: 4),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );

        if (!showPosition) return progressBar;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: progressBar),
            const SizedBox(width: 8),
            Text(
              _formatDuration(position),
              style:
                  positionStyle ??
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                    fontFeatures: [FontFeature.tabularFigures()],
                    shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                  ),
            ),
          ],
        );
      },
    );
  }
}
