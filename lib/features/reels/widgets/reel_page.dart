import 'dart:async';
import 'package:flutter/material.dart';
import 'package:social_media_app/features/reels/widgets/reel_unavailable_fallback.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../model/reel_model.dart';
import 'reel_controls_overlay.dart';

class ReelPage extends StatefulWidget {
  final ReelModel reel;
  final YoutubePlayerController controller;
  final bool keepAlive;
  final ValueChanged<double> onVerticalDragUpdate;
  final ValueChanged<double> onVerticalDragEnd;

  const ReelPage({
    super.key,
    required this.reel,
    required this.controller,
    required this.keepAlive,
    required this.onVerticalDragUpdate,
    required this.onVerticalDragEnd,
  });

  @override
  State<ReelPage> createState() => _ReelPageState();
}

class _ReelPageState extends State<ReelPage> {
  bool _isPaused = false;
  final _hasError = false;
  StreamSubscription<YoutubePlayerValue>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.controller.listen((value) {
      if (value.error != YoutubeError.none && mounted) {
        debugPrint('YT ERROR [${widget.reel.youtubeVideoId}]: ${value.error}');
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _togglePlayback() {
    setState(() => _isPaused = !_isPaused);
    _isPaused ? widget.controller.pauseVideo() : widget.controller.playVideo();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return ReelUnavailableFallback(reel: widget.reel);
    }

    return ColoredBox(
      color: Colors.black,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final aspectRatio = constraints.maxWidth / constraints.maxHeight;
          return YoutubePlayer(
            controller: widget.controller,
            aspectRatio: aspectRatio,
            gestureRecognizers: const {},
            enableFullScreenOnVerticalDrag: false,
            autoFullScreen: false,
            keepAlive: widget.keepAlive,
            controlsBuilder: (context, isFullscreen) {
              return ReelControlsOverlay(
                reel: widget.reel,
                controller: widget.controller,
                isPaused: _isPaused,
                onTogglePlayback: _togglePlayback,
                onVerticalDragUpdate: widget.onVerticalDragUpdate,
                onVerticalDragEnd: widget.onVerticalDragEnd,
              );
            },
          );
        },
      ),
    );
  }
}
