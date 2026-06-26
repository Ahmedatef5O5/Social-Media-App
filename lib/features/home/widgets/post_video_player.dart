import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../../chats/widgets/full_screen_media_view.dart';

class PostVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const PostVideoPlayer({super.key, required this.videoUrl});

  @override
  State<PostVideoPlayer> createState() => _PostVideoPlayerState();
}

class _PostVideoPlayerState extends State<PostVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  final _showControls = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _initializeCachedPlayer();
  }

  Future<void> _initializeCachedPlayer() async {
    try {
      final fileInfo = await DefaultCacheManager().getFileFromCache(
        widget.videoUrl,
      );
      File videoFile =
          fileInfo?.file ??
          await DefaultCacheManager().getSingleFile(widget.videoUrl);

      _controller = VideoPlayerController.file(videoFile);
      await _controller!.initialize();
      _controller!.setLooping(true);

      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint("Video Cache Error: $e");
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
    if (!_isInitialized) return _buildPlaceholder();

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
}
