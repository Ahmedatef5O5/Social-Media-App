import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../model/reel_model.dart';
import 'reel_actions_column.dart';
import 'reel_info_overlay.dart';
import 'reel_video_placeholder.dart';

class ReelControlsOverlay extends StatelessWidget {
  final ReelModel reel;
  final YoutubePlayerController controller;
  final bool isPaused;
  final VoidCallback onTogglePlayback;
  final ValueChanged<double> onVerticalDragUpdate;
  final ValueChanged<double> onVerticalDragEnd;

  const ReelControlsOverlay({
    super.key,
    required this.reel,
    required this.controller,
    required this.isPaused,
    required this.onTogglePlayback,
    required this.onVerticalDragUpdate,
    required this.onVerticalDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTogglePlayback,
            onVerticalDragUpdate:
                (details) => onVerticalDragUpdate(details.delta.dy),
            onVerticalDragEnd:
                (details) => onVerticalDragEnd(details.primaryVelocity ?? 0),
            child: Container(
              color: Colors.transparent,
              child:
                  isPaused
                      ? const Center(
                        child: Icon(
                          Icons.play_arrow,
                          color: Colors.white70,
                          size: 64,
                        ),
                      )
                      : null,
            ),
          ),
        ),

        IgnorePointer(
          child: ReelVideoPlaceholder(controller: controller, reel: reel),
        ),

        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 64,
          child: IgnorePointer(child: ColoredBox(color: Colors.black)),
        ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 64,
          child: IgnorePointer(child: ColoredBox(color: Colors.black)),
        ),

        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 220,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
            ),
          ),
        ),

        Positioned(
          left: 14,
          right: 90,
          bottom: 28,
          child: ReelInfoOverlay(reel: reel),
        ),

        Positioned(right: 10, bottom: 28, child: ReelActionsColumn(reel: reel)),
      ],
    );
  }
}
