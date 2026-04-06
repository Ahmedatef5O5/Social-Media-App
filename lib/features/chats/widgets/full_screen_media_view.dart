import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
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
  final TransformationController _transformationController =
      TransformationController();

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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() => _showControls = !_showControls);
        if (_showControls) _hideControlsAfterDelay();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,

          iconTheme: const IconThemeData(color: Colors.white),
          // ),
        ),
        body: Stack(
          alignment: Alignment.center,
          children: [
            _buildMainContent(),

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
            child: IconButton(
              iconSize: 70,
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
