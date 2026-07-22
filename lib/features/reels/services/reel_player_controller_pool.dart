import 'package:flutter/foundation.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../model/reel_model.dart';

class ReelPlayerControllerPool {
  final Map<int, YoutubePlayerController> _controllers = {};

  static const int _windowBefore = 1;
  static const int _windowAfter = 3;

  YoutubePlayerController controllerFor(
    int index,
    String youtubeVideoId, {
    required bool isActive,
  }) {
    final existing = _controllers[index];
    if (existing != null) return existing;

    debugPrint('VIDEO ID = "$youtubeVideoId"');
    debugPrint('LENGTH = ${youtubeVideoId.length}');

    final controller = YoutubePlayerController.fromVideoId(
      videoId: youtubeVideoId,
      autoPlay: isActive,
      params: const YoutubePlayerParams(
        showControls: false,
        showFullscreenButton: false,
        strictRelatedVideos: true,
        playsInline: true,
        enableJavaScript: true,
        loop: true,
      ),
    );

    _controllers[index] = controller;

    if (!isActive) {
      controller.cueVideoById(videoId: youtubeVideoId);
    }

    return controller;
  }

  void updateActiveIndex(int current, List<ReelModel> reels) {
    final validRange = {
      for (var i = current - _windowBefore; i <= current + _windowAfter; i++) i,
    };

    final toRemove =
        _controllers.keys
            .where((index) => !validRange.contains(index))
            .toList();

    for (final index in toRemove) {
      _controllers[index]?.close();
      _controllers.remove(index);
    }

    for (var i = current; i <= current + _windowAfter; i++) {
      if (i >= 0 && i < reels.length) {
        controllerFor(i, reels[i].youtubeVideoId, isActive: i == current);
      }
    }
  }

  void setActivelyPlaying(int index) {
    for (final entry in _controllers.entries) {
      if (entry.key == index) {
        entry.value.playVideo();
      } else {
        entry.value.pauseVideo();
      }
    }
  }

  bool isWithinWindow(int index, int currentIndex) {
    return index >= currentIndex - _windowBefore &&
        index <= currentIndex + _windowAfter;
  }

  bool get isEmpty => _controllers.isEmpty;

  void disposeAll() {
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
  }
}
