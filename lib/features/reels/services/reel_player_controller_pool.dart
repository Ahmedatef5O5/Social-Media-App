import 'dart:async';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../core/observability/observability.dart';

class ReelPlayerControllerPool {
  ReelPlayerControllerPool({
    YoutubePlayerController Function()? controllerFactory,
  }) : _controllerFactory = controllerFactory ?? _defaultControllerFactory;

  static final RegExp _videoIdPattern = RegExp(r'^[A-Za-z0-9_-]{11}$');
  static bool isValidVideoId(String id) => _videoIdPattern.hasMatch(id);

  final YoutubePlayerController Function() _controllerFactory;

  YoutubePlayerController? _controller;
  final List<YoutubePlayerController> _retired = [];
  String? _loadedVideoId;
  int? _activeIndex;
  bool _isDisposed = false;

  YoutubePlayerController? get controller => _controller;

  int? get activeIndex => _activeIndex;

  int get retiredCount => _retired.length;

  bool isActive(int index) => _activeIndex == index;

  YoutubePlayerController activate(int index, String youtubeVideoId) {
    _ensureAlive();
    if (!isValidVideoId(youtubeVideoId)) {
      throw ArgumentError.value(
        youtubeVideoId,
        'youtubeVideoId',
        'not a valid YouTube video id',
      );
    }

    final current = _controller;
    if (current != null &&
        _activeIndex == index &&
        _loadedVideoId == youtubeVideoId) {
      _run(current.playVideo, operation: 'play');
      return current;
    }

    if (current != null) {
      _retired.add(current);
    }

    final controller = _controllerFactory();
    _controller = controller;
    _activeIndex = index;
    _loadedVideoId = youtubeVideoId;

    _run(
      () => controller.loadVideoById(videoId: youtubeVideoId),
      operation: 'load',
    );
    return controller;
  }

  void pause() {
    if (_isDisposed) return;
    final controller = _controller;
    if (controller == null || _loadedVideoId == null) return;
    _run(controller.pauseVideo, operation: 'pause');
  }

  void play() {
    if (_isDisposed) return;
    final controller = _controller;
    if (controller == null || _loadedVideoId == null) return;
    _run(controller.playVideo, operation: 'play');
  }

  Future<void> disposeRetired() async {
    if (_retired.isEmpty) return;
    final toClose = List<YoutubePlayerController>.of(_retired);
    _retired.clear();
    await Future.wait(toClose.map(_close));
  }

  void _ensureAlive() {
    if (_isDisposed) {
      throw StateError('ReelPlayerControllerPool used after disposeAll()');
    }
  }

  static YoutubePlayerController _defaultControllerFactory() {
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

  /// Player commands are fire-and-forget, but a failure must be reported
  /// instead of escaping as an unhandled error.
  void _run(Future<void> Function() action, {required String operation}) {
    unawaited(
      Future<void>.sync(action).catchError((Object e, StackTrace s) {
        unawaited(
          obs.recordError(
            e,
            s,
            feature: 'reels',
            operation: operation,
            reason: 'player command failed',
            fatal: false,
          ),
        );
      }),
    );
  }

  Future<void> _close(YoutubePlayerController controller) async {
    try {
      await controller.close();
    } catch (e, s) {
      unawaited(
        obs.recordError(
          e,
          s,
          feature: 'reels',
          operation: 'close',
          reason: 'player controller close failed',
          fatal: false,
        ),
      );
    }
  }

  /// Closes everything and waits. Safe to call more than once.
  Future<void> disposeAll() async {
    if (_isDisposed) return;
    _isDisposed = true;

    final all = <YoutubePlayerController>[
      ..._retired,
      if (_controller != null) _controller!,
    ];
    _retired.clear();
    _controller = null;
    _loadedVideoId = null;
    _activeIndex = null;

    await Future.wait(all.map(_close));
  }
}
