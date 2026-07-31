import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoProgressSlider extends StatelessWidget {
  final VideoPlayerController controller;
  final double trackHeight;
  final double thumbSize;

  const VideoProgressSlider({
    super.key,
    required this.controller,
    this.trackHeight = 2.8,
    this.thumbSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    final duration = controller.value.duration;
    final position = controller.value.position;
    final hasDuration = duration > Duration.zero;
    final progress =
        hasDuration
            ? (position.inMilliseconds / duration.inMilliseconds).clamp(
              0.0,
              1.0,
            )
            : 0.0;

    return LayoutBuilder(
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
            height: thumbSize + 2,
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
  }
}
