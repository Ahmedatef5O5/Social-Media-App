import 'dart:async';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../models/reel_model.dart';

class _PooledSlot {
  _PooledSlot(this.controller);

  final YoutubePlayerController controller;
  int? assignedIndex;
  bool isMounted = false;
}

class ReelPlayerControllerPool {
  static const int _windowBefore = 1;
  static const int _windowAfter = 1;
  static const int _poolSize = _windowBefore + _windowAfter + 2; // = 4
  static const Duration _preloadDelay = Duration(milliseconds: 400);

  final List<_PooledSlot> _slots = [];
  Timer? _preloadDelayTimer;

  YoutubePlayerController controllerFor(
    int index,
    String youtubeVideoId, {
    required bool isActive,
  }) {
    final existing = _slotForIndex(index);
    if (existing != null) return existing.controller;

    final slot = _acquireSlot(index);
    slot.assignedIndex = index;

    if (isActive) {
      slot.controller.loadVideoById(videoId: youtubeVideoId);
    } else {
      slot.controller.cueVideoById(videoId: youtubeVideoId);
    }

    return slot.controller;
  }

  void markMounted(YoutubePlayerController controller) {
    _slotForController(controller)?.isMounted = true;
  }

  void markUnmounted(YoutubePlayerController controller) {
    _slotForController(controller)?.isMounted = false;
  }

  _PooledSlot? _slotForController(YoutubePlayerController controller) {
    for (final slot in _slots) {
      if (slot.controller == controller) return slot;
    }
    return null;
  }

  _PooledSlot? _slotForIndex(int index) {
    for (final slot in _slots) {
      if (slot.assignedIndex == index) return slot;
    }
    return null;
  }

  _PooledSlot _acquireSlot(int index) {
    for (final slot in _slots) {
      if (slot.assignedIndex == null && !slot.isMounted) return slot;
    }

    if (_slots.length < _poolSize) {
      final slot = _PooledSlot(_createController());
      _slots.add(slot);
      return slot;
    }

    final stealCandidates =
        _slots.where((s) => !s.isMounted).toList()..sort((a, b) {
          final distanceA =
              a.assignedIndex == null ? -1 : (a.assignedIndex! - index).abs();
          final distanceB =
              b.assignedIndex == null ? -1 : (b.assignedIndex! - index).abs();
          return distanceB.compareTo(distanceA); // farthest first
        });

    if (stealCandidates.isNotEmpty) {
      return stealCandidates.first;
    }

    final slot = _PooledSlot(_createController());
    _slots.add(slot);
    return slot;
  }

  YoutubePlayerController _createController() {
    return YoutubePlayerController(
      params: const YoutubePlayerParams(
        showControls: false,
        showFullscreenButton: false,
        strictRelatedVideos: true,
        playsInline: true,
        enableJavaScript: true,
        loop: true,
      ),
    );
  }

  void updateActiveIndex(int current, List<ReelModel> reels) {
    _preloadDelayTimer?.cancel();
    if (reels.isEmpty) return;

    final validRange = <int>{
      for (var i = current - _windowBefore; i <= current + _windowAfter; i++)
        if (i >= 0 && i < reels.length) i,
    };

    for (final slot in _slots) {
      if (slot.assignedIndex != null &&
          !validRange.contains(slot.assignedIndex)) {
        slot.assignedIndex = null;
      }
    }

    controllerFor(current, reels[current].youtubeVideoId, isActive: true);

    _preloadDelayTimer = Timer(_preloadDelay, () {
      final nextIndex = current + 1;
      if (nextIndex < reels.length) {
        controllerFor(
          nextIndex,
          reels[nextIndex].youtubeVideoId,
          isActive: false,
        );
      }
    });
  }

  void setActivelyPlaying(int index) {
    for (final slot in _slots) {
      if (slot.assignedIndex == null) continue;
      if (slot.assignedIndex == index) {
        slot.controller.playVideo();
      } else {
        slot.controller.pauseVideo();
      }
    }
  }

  bool isWithinWindow(int index, int currentIndex) {
    return index >= currentIndex - _windowBefore &&
        index <= currentIndex + _windowAfter;
  }

  bool get isEmpty => _slots.every((slot) => slot.assignedIndex == null);

  void disposeAll() {
    _preloadDelayTimer?.cancel();
    for (final slot in _slots) {
      slot.controller.close();
    }
    _slots.clear();
  }
}
