import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'circle_icon_btn.dart';
import 'dismissible_video_overlay.dart';

class PostVideoHeaderWidget extends StatelessWidget {
  const PostVideoHeaderWidget({
    super.key,
    required ValueNotifier<bool> showOverlays,
    required Duration fadeDuration,
    required VideoPlayerController controller,
    required this.context,
  }) : _showOverlays = showOverlays,
       _fadeDuration = fadeDuration,
       _controller = controller;

  final ValueNotifier<bool> _showOverlays;
  final Duration _fadeDuration;
  final VideoPlayerController _controller;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return DismissibleVideoOverlay(
      listenable: _showOverlays,
      fadeDuration: _fadeDuration,
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleIconButton(
              icon: Icons.arrow_back_rounded,
              onTap: () => Navigator.of(context).pop(),
            ),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final isMuted = _controller.value.volume == 0.0;
                return CircleIconButton(
                  icon:
                      isMuted
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                  onTap: () => _controller.setVolume(isMuted ? 1.0 : 0.0),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
