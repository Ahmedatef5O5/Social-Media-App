import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:social_media_app/core/widgets/cached_cloudinary_image.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import '../../../core/cache/repository/media_cache_repository.dart';
import '../../../core/cache/utils/cloudinary_url_extensions.dart';
import '../model/story_model.dart';

class StoryMediaView extends StatefulWidget {
  final StoryModel story;
  final void Function(Duration?) onMediaReady;
  final VoidCallback onVideoFinished;
  final void Function(VideoPlayerController) onVideoControllerReady;

  const StoryMediaView({
    super.key,
    required this.story,
    required this.onMediaReady,
    required this.onVideoFinished,
    required this.onVideoControllerReady,
  });

  @override
  State<StoryMediaView> createState() => _StoryMediaViewState();
}

class _StoryMediaViewState extends State<StoryMediaView> {
  VideoPlayerController? _videoController;
  bool _videoReady = false;
  bool _videoError = false;

  Uint8List? _localThumbnailBytes;

  @override
  void initState() {
    super.initState();
    if (widget.story.storyType == StoryType.video) {
      _initVideo();
    }
    if (widget.story.storyType == StoryType.text) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => widget.onMediaReady(null),
      );
    }
  }

  Future<void> _initVideo() async {
    try {
      final localPath = await context
          .read<MediaCacheRepository>()
          .resolveLocalPath(widget.story.videoUrl!);

      if (localPath != null) {
        _videoController = VideoPlayerController.file(File(localPath));
        unawaited(_generateLocalThumbnail(localPath));
      } else {
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(widget.story.videoUrl!),
        );
      }

      _videoController!.addListener(_onVideoUpdate);

      _videoController!
          .initialize()
          .then((_) {
            if (!mounted) return;
            setState(() {
              _videoReady = true;
            });
            _videoController!.play();
            widget.onVideoControllerReady(_videoController!);

            Duration reportedDuration = _videoController!.value.duration;
            int? dbDurationSeconds = widget.story.videoDurationSeconds;

            if (reportedDuration.inMilliseconds < 500 &&
                dbDurationSeconds != null &&
                dbDurationSeconds > 0) {
              widget.onMediaReady(Duration(seconds: dbDurationSeconds));
            } else {
              widget.onMediaReady(reportedDuration);
            }
          })
          .catchError((error) {
            debugPrint('Error initializing video: $error');
            if (mounted) setState(() => _videoError = true);
            widget.onMediaReady(const Duration(seconds: 5));
          });
    } catch (e) {
      debugPrint('Error in _initVideo: $e');
      if (mounted) setState(() => _videoError = true);
      widget.onMediaReady(const Duration(seconds: 5));
    }
  }

  Future<void> _generateLocalThumbnail(String localFilePath) async {
    try {
      final bytes = await VideoThumbnail.thumbnailData(
        video: localFilePath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 250,
        quality: 35,
      );
      if (!mounted || bytes == null) return;
      setState(() => _localThumbnailBytes = bytes);
    } catch (e) {
      debugPrint('StoryMediaView: local thumbnail generation failed - $e');
    }
  }

  void _onVideoUpdate() {
    if (_videoController == null) return;
    final v = _videoController!.value;

    if (!v.isInitialized) return;

    if (v.duration.inMilliseconds < 500) return;

    if (v.position >= v.duration && !v.isPlaying) {
      widget.onVideoFinished();
    }
  }

  @override
  void dispose() {
    _videoController?.removeListener(_onVideoUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.story.storyType) {
      case StoryType.video:
        if (_videoError) {
          return const ColoredBox(
            color: Colors.black,
            child: Center(
              child: Icon(Icons.videocam_off, color: Colors.white54),
            ),
          );
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child:
              !_videoReady
                  ? _buildBlurredVideoPlaceholder()
                  : Center(
                    key: const ValueKey('video-ready'),
                    child: AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    ),
                  ),
        );

      case StoryType.image:
        return CachedCloudinaryImage(
          secureUrl: widget.story.imageUrl!,
          fit: BoxFit.contain,
          onReady: () => widget.onMediaReady(null),
          placeholder:
              (context) =>
                  _buildBlurredImagePlaceholder(widget.story.imageUrl!),
        );

      case StoryType.text:
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Color(
            int.parse(widget.story.backgroundColor ?? 'ff9c27b0', radix: 16),
          ),
        );
    }
  }

  Widget _buildBlurredVideoPlaceholder() {
    final networkThumbnailUrl =
        widget.story.videoUrl?.cloudinaryVideoThumbnailUrl;
    final hasThumbnail =
        _localThumbnailBytes != null || networkThumbnailUrl != null;

    return Stack(
      key: const ValueKey('video-loading'),
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.black),

        if (_localThumbnailBytes != null)
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Image.memory(
              _localThumbnailBytes!,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          )
        else if (networkThumbnailUrl != null)
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: CachedCloudinaryImage(
              secureUrl: networkThumbnailUrl,
              fit: BoxFit.cover,
              placeholder: (_) => const SizedBox.shrink(),
              errorWidget: (_, __) => const SizedBox.shrink(),
            ),
          ),

        Container(color: Colors.black.withValues(alpha: 0.25)),

        if (hasThumbnail)
          Center(
            child:
                _localThumbnailBytes != null
                    ? Image.memory(
                      _localThumbnailBytes!,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    )
                    : CachedCloudinaryImage(
                      secureUrl: networkThumbnailUrl!,
                      fit: BoxFit.contain,
                      placeholder: (_) => const SizedBox.shrink(),
                      errorWidget: (_, __) => const SizedBox.shrink(),
                    ),
          ),

        const Center(
          child: CustomLoadingIndicator(color: Colors.white, radius: 14),
        ),
      ],
    );
  }

  Widget _buildBlurredImagePlaceholder(String secureUrl) {
    final lowResUrl = secureUrl.cloudinaryLowResPreviewUrl;

    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.black),

        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Image.network(
            lowResUrl,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
        Container(color: Colors.black.withValues(alpha: 0.25)),

        SizedBox.expand(
          child: Image.network(
            lowResUrl,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),

        const Center(
          child: CustomLoadingIndicator(color: Colors.white, radius: 14),
        ),
      ],
    );
  }
}
