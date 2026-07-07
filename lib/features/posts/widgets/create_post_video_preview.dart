import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class CreatePostVideoPreview extends StatefulWidget {
  final String videoPath;
  final VoidCallback onRemove;

  const CreatePostVideoPreview({
    super.key,
    required this.videoPath,
    required this.onRemove,
  });

  @override
  State<CreatePostVideoPreview> createState() => _CreatePostVideoPreviewState();
}

class _CreatePostVideoPreviewState extends State<CreatePostVideoPreview> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.black,
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: _isInitialized ? _controller.value.aspectRatio : 16 / 9,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_isInitialized)
              VideoPlayer(_controller)
            else
              const CircularProgressIndicator(),

            GestureDetector(
              onTap: () {
                setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                });
              },
              child: Container(
                color: Colors.transparent,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _controller.value.isPlaying ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.black45,
                      child: Icon(
                        _controller.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Remove Button
            Positioned(
              top: 8,
              right: 8,
              child: InkWell(
                onTap: widget.onRemove,
                child: CircleAvatar(
                  radius: 15,
                  backgroundColor: Colors.black54,
                  child: const Icon(Icons.close, size: 18, color: Colors.white),
                ),
              ),
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: Theme.of(context).primaryColor,
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.white10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
