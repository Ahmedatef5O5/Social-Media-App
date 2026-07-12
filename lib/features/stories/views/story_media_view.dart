import 'dart:io';
import 'package:social_media_app/core/widgets/cached_cloudinary_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:story_view/story_view.dart';
import 'package:video_player/video_player.dart';
import '../../../core/cache/repository/media_cache_repository.dart';
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
  final _storyController = StoryController();
  VideoPlayerController? _videoController;
  bool _videoReady = false;
  bool _videoError = false;

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
      final file = await context.read<MediaCacheRepository>().resolveLocalPath(
        widget.story.videoUrl!,
      );
      if (file != null) {
        _videoController = VideoPlayerController.file(File(file));
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
        if (!_videoReady) {
          return const Center(child: CircularProgressIndicator());
        }
        return Center(
          child: AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
        );

      case StoryType.image:
        return CachedCloudinaryImage(
          secureUrl: widget.story.imageUrl!,
          fit: BoxFit.contain,
          onReady: () => widget.onMediaReady(null),
        );

      case StoryType.text:
        return StoryView(
          controller: _storyController,
          inline: true,
          progressPosition: ProgressPosition.none,
          storyItems: [
            StoryItem.text(
              title: widget.story.contentText ?? '',
              backgroundColor: Color(
                int.parse(
                  widget.story.backgroundColor ?? 'ff9c27b0',
                  radix: 16,
                ),
              ),
              textStyle: const TextStyle(fontSize: 28, color: Colors.white),
            ),
          ],
        );
    }
  }
}
