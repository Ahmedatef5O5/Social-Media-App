import 'dart:async';
import 'package:flutter/material.dart';
import 'package:social_media_app/features/reels/widgets/reel_unavailable_fallback.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../models/reel_model.dart';
import 'reel_controls_overlay.dart';

class ReelPage extends StatefulWidget {
  final ReelModel reel;
  final YoutubePlayerController? controller;
  final ValueChanged<double> onVerticalDragUpdate;
  final ValueChanged<double> onVerticalDragEnd;

  const ReelPage({
    super.key,
    required this.reel,
    required this.controller,
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
    _attach(widget.controller);
  }

  @override
  void didUpdateWidget(covariant ReelPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _sub?.cancel();
      _sub = null;
      _isPaused = false;
      _attach(widget.controller);
    }
  }

  void _attach(YoutubePlayerController? controller) {
    _sub = controller?.listen((value) {
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
    final controller = widget.controller;
    if (controller == null) return;
    setState(() => _isPaused = !_isPaused);
    _isPaused ? controller.pauseVideo() : controller.playVideo();
  }

  Widget _overlay(YoutubePlayerController? controller) {
    return ReelControlsOverlay(
      reel: widget.reel,
      controller: controller,
      isPaused: _isPaused,
      onTogglePlayback: _togglePlayback,
      onVerticalDragUpdate: widget.onVerticalDragUpdate,
      onVerticalDragEnd: widget.onVerticalDragEnd,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return ReelUnavailableFallback(reel: widget.reel);
    }

    final controller = widget.controller;
    if (controller == null) {
      return ColoredBox(color: Colors.black, child: _overlay(null));
    }

    return ColoredBox(
      color: Colors.black,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final aspectRatio = constraints.maxWidth / constraints.maxHeight;
          return YoutubePlayer(
            controller: controller,
            aspectRatio: aspectRatio,
            gestureRecognizers: const {},
            enableFullScreenOnVerticalDrag: false,
            autoFullScreen: false,
            backgroundColor: Colors.black,
            controlsBuilder: (context, isFullscreen) => _overlay(controller),
          );
        },
      ),
    );
  }
}
