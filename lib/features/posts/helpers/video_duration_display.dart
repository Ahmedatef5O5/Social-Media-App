import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'fade_dismiss_widget.dart';

class VideoDurationDisplay extends StatelessWidget {
  const VideoDurationDisplay({
    super.key,
    required ValueNotifier<bool> showOverlays,
    required Duration fadeDuration,
    required VideoPlayerController controller,
  }) : _showOverlays = showOverlays,
       _fadeDuration = fadeDuration,
       _controller = controller;

  final ValueNotifier<bool> _showOverlays;
  final Duration _fadeDuration;
  final VideoPlayerController _controller;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 14,
      bottom: 24,
      child: SafeArea(
        top: false,
        child: FadeDismissWidget(
          listenable: _showOverlays,
          fadeDuration: _fadeDuration,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              if (!_controller.value.isInitialized) {
                return const SizedBox.shrink();
              }

              final duration = _controller.value.duration;
              final position = _controller.value.position;

              String format(Duration d) {
                final mins = d.inMinutes
                    .remainder(60)
                    .toString()
                    .padLeft(2, '0');
                final secs = d.inSeconds
                    .remainder(60)
                    .toString()
                    .padLeft(2, '0');
                return d.inHours > 0
                    ? '${d.inHours}:$mins:$secs'
                    : '$mins:$secs';
              }

              return Text(
                '${format(position)} / ${format(duration)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black87)],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
