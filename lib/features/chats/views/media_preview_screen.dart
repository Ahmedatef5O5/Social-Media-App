import 'dart:io';
import 'package:flutter/material.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import 'package:video_player/video_player.dart';
import '../../../core/themes/app_colors.dart';

class MediaPreviewScreen extends StatefulWidget {
  final File file;
  final String type;
  final Function(String? caption) onSend;

  const MediaPreviewScreen({
    super.key,
    required this.file,
    required this.type,
    required this.onSend,
  });

  @override
  State<MediaPreviewScreen> createState() => _MediaPreviewScreenState();
}

class _MediaPreviewScreenState extends State<MediaPreviewScreen> {
  final TextEditingController _captionController = TextEditingController();
  VideoPlayerController? _videoPlayerController;

  @override
  void initState() {
    super.initState();
    if (widget.type == 'video') {
      _videoPlayerController = VideoPlayerController.file(widget.file)
        ..initialize().then((_) {
          setState(() {});
          _videoPlayerController!.play();
          _videoPlayerController!.setLooping(true);
        });
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _captionController.dispose();
    super.dispose();
  }

  Widget _buildVideoControls() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _videoPlayerController!.value.isPlaying
              ? _videoPlayerController!.pause()
              : _videoPlayerController!.play();
        });
      },
      child: CircleAvatar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor.withValues(),
        radius: 30,
        child: Icon(
          _videoPlayerController!.value.isPlaying
              ? Icons.pause
              : Icons.play_arrow,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: AppColors.black,
        appBar: AppBar(
          backgroundColor: AppColors.black,
          iconTheme: const IconThemeData(color: AppColors.white),
        ),
        body: Column(
          children: [
            Expanded(
              child: Center(
                child:
                    widget.type == 'image'
                        ? Image.file(widget.file, fit: BoxFit.contain)
                        : _videoPlayerController != null &&
                            _videoPlayerController!.value.isInitialized
                        ? AspectRatio(
                          aspectRatio:
                              _videoPlayerController!.value.aspectRatio,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              VideoPlayer(_videoPlayerController!),
                              _buildVideoControls(),
                            ],
                          ),
                        )
                        : const CustomLoadingIndicator(),
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              color: Colors.black54,
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _captionController,
                        style: const TextStyle(color: AppColors.white),
                        decoration: InputDecoration(
                          hintText: "Add an optional caption...",
                          hintStyle: const TextStyle(color: AppColors.white60),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          fillColor: Colors.white12,
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: IconButton(
                        icon: const Icon(Icons.send, color: AppColors.white),
                        onPressed: () {
                          widget.onSend(_captionController.text.trim());
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
