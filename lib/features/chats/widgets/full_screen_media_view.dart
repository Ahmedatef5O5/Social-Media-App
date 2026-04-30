import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../core/services/gallery_services.dart';
import '../../../core/widgets/custom_loading_indicator.dart';

class FullScreenMediaView extends StatefulWidget {
  final String? imageUrl;
  final String? videoUrl;
  final String? caption;

  const FullScreenMediaView({
    super.key,
    this.imageUrl,
    this.videoUrl,
    this.caption,
  });

  @override
  State<FullScreenMediaView> createState() => _FullScreenMediaViewState();
}

class _FullScreenMediaViewState extends State<FullScreenMediaView> {
  VideoPlayerController? _videoController;
  bool _showControls = true;
  double _playbackSpeed = 1.0;
  double _dragOffset = 0;

  final TransformationController _transformationController =
      TransformationController();
  void _changeSpeed() {
    setState(() {
      if (_playbackSpeed == 1.0) {
        _playbackSpeed = 1.5;
      } else if (_playbackSpeed == 1.5) {
        _playbackSpeed = 2.0;
      } else if (_playbackSpeed == 2.0) {
        _playbackSpeed = 0.5;
      } else {
        _playbackSpeed = 1.0;
      }

      _videoController?.setPlaybackSpeed(_playbackSpeed);
    });
  }

  void _seekRelative(Duration offset) {
    if (_videoController != null) {
      final newPosition = _videoController!.value.position + offset;
      _videoController!.seekTo(newPosition);
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.videoUrl != null) {
      _videoController = VideoPlayerController.networkUrl(
          Uri.parse(widget.videoUrl!),
        )
        ..initialize().then((_) {
          setState(() {});

          _videoController!.play();
          _hideControlsAfterDelay();
        });
    }
  }

  void _hideControlsAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _videoController!.value.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  @override
  void dispose() {
    _videoController?.pause();
    _videoController?.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      _transformationController.value = Matrix4.identity();
    } else {
      _transformationController.value = Matrix4.identity()..scale(2.0);
    }
    setState(() {});
  }

  bool _isSaving = false;

  Future<void> _saveMediaToGallery() async {
    final url = widget.imageUrl ?? widget.videoUrl;
    if (url == null) return;

    setState(() => _isSaving = true);

    await GalleryServices.saveMediaToGallery(
      context: context,
      url: url,
      isVideo: widget.videoUrl != null,
    );

    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleUpdate: (details) {
        if (_transformationController.value.getMaxScaleOnAxis() <= 1.0) {
          setState(() {
            _dragOffset += details.focalPointDelta.dy;
          });
        }
      },

      onScaleEnd: (details) {
        if (_dragOffset.abs() > 150) {
          Navigator.pop(context);
        } else {
          setState(() {
            _dragOffset = 0;
          });
        }
      },
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() => _showControls = !_showControls);
        if (_showControls) _hideControlsAfterDelay();
      },
      child: Scaffold(
        backgroundColor: Colors.black.withValues(
          alpha: (.95 - (_dragOffset.abs() / 500)).clamp(0.0, 1.0),
        ),
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,

          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            if (widget.imageUrl != null)
              _isSaving
                  ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CustomLoadingIndicator(color: Colors.white),
                    ),
                  )
                  : PopupMenuButton<String>(
                    color: Colors.white,
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    offset: const Offset(-24, kToolbarHeight - 12),
                    onSelected: (value) {
                      if (value == 'save') {
                        _saveMediaToGallery();
                      }
                    },
                    itemBuilder:
                        (_) => [
                          const PopupMenuItem(
                            value: 'save',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.download,
                                  size: 18,
                                  color: Colors.black45,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Save to gallery',
                                  style: TextStyle(color: Colors.black45),
                                ),
                              ],
                            ),
                          ),
                        ],
                  ),

            if (widget.videoUrl != null && _showControls)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: TextButton(
                  onPressed: _changeSpeed,
                  child: Text(
                    "${_playbackSpeed}x",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: Stack(
          alignment: Alignment.center,
          children: [
            Transform.translate(
              offset: Offset(0, _dragOffset),
              child: _buildMainContent(),
            ),

            if (widget.videoUrl != null &&
                _videoController != null &&
                _videoController!.value.isInitialized)
              _buildVideoOverlay(),

            if (widget.caption != null && widget.caption!.isNotEmpty)
              _buildCaption(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (widget.imageUrl != null) {
      return Center(
        child: GestureDetector(
          onDoubleTap: _handleDoubleTap,
          child: InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.5,
            maxScale: 4.0,
            child: CachedNetworkImage(
              imageUrl: widget.imageUrl!,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
              placeholder: (context, url) => const CustomLoadingIndicator(),
              errorWidget:
                  (context, url, error) => const Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: 50,
                  ),
            ),
          ),
        ),
      );
    } else if (_videoController != null &&
        _videoController!.value.isInitialized) {
      return Center(
        child: AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        ),
      );
    }
    return const CustomLoadingIndicator();
  }

  Widget _buildVideoOverlay() {
    return AnimatedOpacity(
      opacity: _showControls ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Stack(
        children: [
          Container(color: Colors.black26),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.replay_5,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () => _seekRelative(const Duration(seconds: -5)),
                ),

                IconButton(
                  iconSize: 60,
                  icon: Icon(
                    _videoController!.value.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _videoController!.value.isPlaying
                          ? _videoController!.pause()
                          : _videoController!.play();
                    });
                    _hideControlsAfterDelay();
                  },
                ),

                IconButton(
                  icon: const Icon(
                    Icons.forward_5,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () => _seekRelative(const Duration(seconds: 5)),
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              children: [
                VideoProgressIndicator(
                  _videoController!,
                  allowScrubbing: true,
                  colors: VideoProgressColors(
                    playedColor: Theme.of(context).primaryColor,
                    bufferedColor: Colors.white24,
                    backgroundColor: Colors.white12,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTimeText(_videoController!.value.position),
                    _buildTimeText(_videoController!.value.duration),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeText(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return Text(
      "$minutes:$seconds",
      style: const TextStyle(color: Colors.white, fontSize: 12),
    );
  }

  Widget _buildCaption() {
    return Positioned(
      bottom: widget.videoUrl != null ? 80 : 40,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          widget.caption!,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
