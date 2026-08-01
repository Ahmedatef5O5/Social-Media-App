import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import '../../../core/cache/repository/media_cache_repository.dart';
import '../../../core/router/app_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/services/network_status_service.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../cubit/posts_cubit/posts_cubit.dart';
import '../helper/global_video_pause_gate.dart';
import '../helper/shared_video_controller_handle.dart';
import '../model/post_model.dart';
import 'full_screen_video_post_view.dart';

enum _VideoLoadStatus { loading, ready, unavailableOffline, processing, error }

class PostVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final PostModel post;
  final PostsCubit postsCubit;
  final String currentUserId;
  final double? aspectRatio;

  const PostVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.post,
    required this.postsCubit,
    required this.currentUserId,
    this.aspectRatio,
  });

  @override
  State<PostVideoPlayer> createState() => _PostVideoPlayerState();
}

class _PostVideoPlayerState extends State<PostVideoPlayer> with RouteAware {
  VideoPlayerController? _controller;
  SharedVideoControllerHandle? _handle;
  _VideoLoadStatus _status = _VideoLoadStatus.loading;

  final _showControls = ValueNotifier<bool>(false);
  bool _isLentToFullScreen = false;
  bool _wasPlayingBeforeGlobalPause = false;
  double _lastVisibleFraction = 0;
  static const int _maxDurationRetries = 3;
  int _durationRetryAttempt = 0;

  @override
  void initState() {
    super.initState();
    _initializeCachedPlayer();
    GlobalVideoPauseGate.instance.isPaused.addListener(
      _handleGlobalPauseChange,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  Future<void> _initializeCachedPlayer({bool ignoreCache = false}) async {
    if (mounted) setState(() => _status = _VideoLoadStatus.loading);

    try {
      final localPath =
          ignoreCache
              ? null
              : await context.read<MediaCacheRepository>().resolveLocalPath(
                widget.videoUrl,
              );

      if (localPath != null) {
        _controller = VideoPlayerController.file(File(localPath));
      } else {
        final isOnline = await NetworkStatusService.instance.isConnected();
        if (!isOnline) {
          if (mounted) {
            setState(() => _status = _VideoLoadStatus.unavailableOffline);
          }
          return;
        }
        _controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.videoUrl),
        );
      }

      await _controller!.initialize().timeout(const Duration(seconds: 15));

      final bool metadataLooksIncomplete =
          _controller!.value.duration.inMilliseconds <= 500;

      if (metadataLooksIncomplete) {
        await _controller!.dispose();
        _controller = null;

        if (localPath != null) {
          if (!mounted) return;
          return _initializeCachedPlayer(ignoreCache: true);
        }

        if (_durationRetryAttempt < _maxDurationRetries) {
          _durationRetryAttempt++;
          await Future.delayed(Duration(seconds: 2 * _durationRetryAttempt));
          if (!mounted) return;
          return _initializeCachedPlayer(ignoreCache: true);
        } else {
          if (mounted) setState(() => _status = _VideoLoadStatus.processing);
          return;
        }
      }

      _controller!.setLooping(true);

      double initialVolume = 0.0;
      if (mounted) {
        final routeName = ModalRoute.of(context)?.settings.name;
        if (routeName == AppRoutes.postDetailsViewRoute) {
          initialVolume = 1.0;
        }
      }
      _controller!.setVolume(initialVolume);

      _handle = SharedVideoControllerHandle(_controller!)..acquire();

      if (mounted) setState(() => _status = _VideoLoadStatus.ready);
    } catch (e, stackTrace) {
      debugPrint("Video init error: $e");
      debugPrintStack(stackTrace: stackTrace);
      await _controller?.dispose();
      _controller = null;
      _handle = null;
      if (mounted) setState(() => _status = _VideoLoadStatus.error);
    }
  }

  void _retryInitialization() {
    _durationRetryAttempt = 0;
    _initializeCachedPlayer(ignoreCache: true);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    GlobalVideoPauseGate.instance.isPaused.removeListener(
      _handleGlobalPauseChange,
    );
    _handle?.release();
    _showControls.dispose();
    super.dispose();
  }

  @override
  void didPushNext() {
    if (!_isLentToFullScreen &&
        _controller != null &&
        _controller!.value.isPlaying) {
      _controller!.pause();
      _showControls.value = true;
    }
  }

  @override
  void didPopNext() {
    if (!_isLentToFullScreen &&
        _controller != null &&
        _lastVisibleFraction >= 0.6) {
      _controller!.play();
    }
  }

  void _togglePlayPause() {
    if (_controller == null) return;
    if (_controller!.value.isPlaying) {
      _controller!.pause();
    } else {
      _controller!.play();
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted && _controller!.value.isPlaying) {
          _showControls.value = false;
        }
      });
    }
  }

  void _handleGlobalPauseChange() {
    if (_controller == null || !mounted) return;
    final shouldPause = GlobalVideoPauseGate.instance.isPaused.value;

    if (shouldPause) {
      _wasPlayingBeforeGlobalPause = _controller!.value.isPlaying;
      if (_wasPlayingBeforeGlobalPause) _controller!.pause();
    } else if (_wasPlayingBeforeGlobalPause &&
        !_isLentToFullScreen &&
        _lastVisibleFraction >= 0.6) {
      _controller!.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_status) {
      case _VideoLoadStatus.loading:
        return _buildPlaceholder();
      case _VideoLoadStatus.unavailableOffline:
        return _buildMessageBox(
          icon: Icons.wifi_off_rounded,
          message: 'Video unavailable offline',
          showRetry: true,
        );
      case _VideoLoadStatus.processing:
        return _buildMessageBox(
          icon: Icons.hourglass_top_rounded,
          message: 'Video is still processing…',
          showRetry: true,
        );

      case _VideoLoadStatus.error:
        return _buildMessageBox(
          icon: Icons.error_outline_rounded,
          message: "Couldn't load video",
          showRetry: true,
        );
      case _VideoLoadStatus.ready:
        return _buildPlayer();
    }
  }

  Widget _buildPlayer() {
    return VisibilityDetector(
      key: Key(widget.videoUrl),
      onVisibilityChanged: (info) {
        _lastVisibleFraction = info.visibleFraction;
        if (_isLentToFullScreen) return;

        if (!mounted ||
            _controller == null ||
            !_controller!.value.isInitialized) {
          return;
        }

        if (info.visibleFraction >= 0.6) {
          if (!_controller!.value.isPlaying) {
            _controller!.play();
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (mounted && _controller!.value.isPlaying) {
                _showControls.value = false;
              }
            });
          }
        } else if (info.visibleFraction < 0.4) {
          if (_controller!.value.isPlaying) {
            _controller!.pause();
            _showControls.value = true;
          }
        }
      },
      child: GestureDetector(
        onTap: () => _showControls.value = !_showControls.value,
        onDoubleTap: _goToFullScreen,
        child: AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(_controller!),

                ValueListenableBuilder<bool>(
                  valueListenable: _showControls,
                  builder: (context, showControls, _) {
                    return AnimatedOpacity(
                      opacity: showControls ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child:
                          showControls
                              ? _buildMinimalControls()
                              : const SizedBox.shrink(),
                    );
                  },
                ),
                _buildSlimProgressBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalControls() {
    return Container(
      color: Colors.black38,
      child: Stack(
        children: [
          Center(
            child: AnimatedBuilder(
              animation: _controller!,
              builder: (context, _) {
                return IconButton(
                  iconSize: 35,
                  icon: Icon(
                    _controller!.value.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    color: Colors.white,
                  ),
                  onPressed: _togglePlayPause,
                );
              },
            ),
          ),

          Positioned(
            top: 2,
            left: 2,
            child: AnimatedBuilder(
              animation: _controller!,
              builder: (context, _) {
                final isMuted = _controller!.value.volume == 0.0;
                return IconButton(
                  icon: Icon(
                    isMuted
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () {
                    _controller!.setVolume(isMuted ? 1.0 : 0.0);
                  },
                );
              },
            ),
          ),

          Positioned(
            top: 2,
            right: 2,
            child: IconButton(
              icon: const Icon(Icons.fullscreen, color: Colors.white, size: 20),
              onPressed: _goToFullScreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlimProgressBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: RepaintBoundary(
        child: SizedBox(
          height: 3,
          child: VideoProgressIndicator(
            _controller!,
            allowScrubbing: true,
            colors: VideoProgressColors(
              playedColor: Theme.of(context).primaryColor,
              bufferedColor: Colors.white24,
              backgroundColor: Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }

  void _goToFullScreen() {
    if (_controller == null || _handle == null) return;

    _isLentToFullScreen = true;

    Navigator.of(context, rootNavigator: true)
        .push(
          MaterialPageRoute(
            builder:
                (context) => FullScreenVideoPostView(
                  post: widget.post,
                  handle: _handle!,
                  postsCubit: widget.postsCubit,
                  currentUserId: widget.currentUserId,
                ),
          ),
        )
        .then((_) {
          _isLentToFullScreen = false;
          if (mounted) _showControls.value = false;
        });
  }

  Widget _buildPlaceholder() {
    return AspectRatio(
      aspectRatio: widget.aspectRatio ?? 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.grey4.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: CustomLoadingIndicator()),
      ),
    );
  }

  Widget _buildMessageBox({
    required IconData icon,
    required String message,
    required bool showRetry,
  }) {
    return AspectRatio(
      aspectRatio: widget.aspectRatio ?? 16 / 9,

      child: Container(
        decoration: BoxDecoration(
          color: AppColors.grey4.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.grey2, size: 30),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  color: AppColors.grey2,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (showRetry) ...[
                const SizedBox(height: 10),
                InkWell(
                  onTap: _retryInitialization,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: Text(
                      'Retry',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
