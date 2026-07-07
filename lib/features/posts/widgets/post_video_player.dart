import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import '../../../core/cache/repository/media_cache_repository.dart';
import '../../../core/services/network_status_service.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../../single_chats/widgets/full_screen_media_view.dart';

enum _VideoLoadStatus { loading, ready, unavailableOffline, error }

class PostVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const PostVideoPlayer({super.key, required this.videoUrl});

  @override
  State<PostVideoPlayer> createState() => _PostVideoPlayerState();
}

class _PostVideoPlayerState extends State<PostVideoPlayer> {
  VideoPlayerController? _controller;
  _VideoLoadStatus _status = _VideoLoadStatus.loading;

  final _showControls = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _initializeCachedPlayer();
  }

  Future<void> _initializeCachedPlayer() async {
    if (mounted) setState(() => _status = _VideoLoadStatus.loading);

    try {
      final localPath = await context
          .read<MediaCacheRepository>()
          .resolveLocalPath(widget.videoUrl);

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
      _controller!.setLooping(true);

      if (mounted) setState(() => _status = _VideoLoadStatus.ready);
    } catch (e, stackTrace) {
      debugPrint("Video init error: $e");
      debugPrintStack(stackTrace: stackTrace);
      await _controller?.dispose();
      _controller = null;
      if (mounted) setState(() => _status = _VideoLoadStatus.error);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _showControls.dispose();
    super.dispose();
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
        if (info.visibleFraction <= 0 &&
            mounted &&
            _controller!.value.isPlaying) {
          _controller?.pause();
        }
      },
      child: GestureDetector(
        onTap: () => _showControls.value = !_showControls.value,
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
                  iconSize: 55,
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
            top: 10,
            right: 10,
            child: IconButton(
              icon: const Icon(Icons.fullscreen, color: Colors.white, size: 28),
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
    _controller?.pause();
    Navigator.of(context, rootNavigator: true)
        .push(
          MaterialPageRoute(
            builder:
                (context) => FullScreenMediaView(videoUrl: widget.videoUrl),
          ),
        )
        .then((_) {
          if (mounted) _controller?.play();
        });
  }

  Widget _buildPlaceholder() {
    return AspectRatio(
      aspectRatio: 16 / 9,
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
      aspectRatio: 16 / 9,
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
                  onTap: _initializeCachedPlayer,
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
