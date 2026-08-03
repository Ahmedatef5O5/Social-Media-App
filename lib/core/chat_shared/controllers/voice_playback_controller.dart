import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

class VoicePlaybackController {
  VoicePlaybackController._();
  static final VoicePlaybackController instance = VoicePlaybackController._();

  final ValueNotifier<String?> activeVoiceUrl = ValueNotifier<String?>(null);

  final Map<String, VideoPlayerController> cache = {};
  final Map<String, Duration> durationCache = {};
  final Map<String, Future<void>> _preloadFutures = {};

  static const Duration minReliableDuration = Duration(seconds: 1);

  VideoPlayerController? controllerFor(String url) => cache[url];

  bool get isAnyPlaying => activeVoiceUrl.value != null;

  void stopActiveIfDifferent(String url) {
    final active = activeVoiceUrl.value;
    if (active != null && active != url) {
      cache[active]?.pause();
    }
  }

  void markStopped(String url) {
    if (activeVoiceUrl.value == url) {
      activeVoiceUrl.value = null;
    }
  }

  void setActive(String url) {
    stopActiveIfDifferent(url);
    activeVoiceUrl.value = url;
  }

  Future<Duration?> fetchDuration(String url) async {
    if (durationCache.containsKey(url)) return durationCache[url];
    if (_preloadFutures.containsKey(url)) {
      await _preloadFutures[url];
      return durationCache[url];
    }

    final completer = Completer<void>();
    _preloadFutures[url] = completer.future;
    VideoPlayerController? temp;
    try {
      final isLocal = url.startsWith('/');
      temp =
          isLocal
              ? VideoPlayerController.file(File(url))
              : VideoPlayerController.networkUrl(Uri.parse(url));
      await temp.initialize();
      final duration = temp.value.duration;
      await temp.dispose();
      temp = null;
      if (duration >= minReliableDuration) {
        durationCache[url] = duration;
      }
      completer.complete();
      return duration;
    } catch (e) {
      completer.completeError(e);
      return null;
    } finally {
      await temp?.dispose();
      _preloadFutures.remove(url);
    }
  }

  void register(String url, VideoPlayerController controller) {
    cache[url] = controller;
    if (controller.value.duration >= minReliableDuration) {
      durationCache[url] = controller.value.duration;
    }
  }

  Future<void> clearCache() async {
    activeVoiceUrl.value = null;
    _preloadFutures.clear();
    for (final c in cache.values) {
      await c.dispose();
    }
    cache.clear();
    durationCache.clear();
  }
}
