import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../core/themes/app_colors.dart';
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
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Stack(
          children: [
            Center(
              child:
                  widget.imageUrl != null
                      ? InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: CachedNetworkImage(
                          imageUrl: widget.imageUrl!,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                          placeholder:
                              (context, url) => const CustomLoadingIndicator(),
                          errorWidget:
                              (context, url, error) => const Icon(
                                Icons.broken_image,
                                color: Colors.white,
                              ),
                        ),
                      )
                      : _videoController != null &&
                          _videoController!.value.isInitialized
                      ? AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      )
                      : const CustomLoadingIndicator(),
            ),

            if (widget.caption != null && widget.caption!.isNotEmpty)
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: MediaQuery.sizeOf(context).width * 0.85,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.black54,

                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    textAlign: TextAlign.center,
                    widget.caption!,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
        floatingActionButton:
            widget.videoUrl != null
                ? FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      _videoController!.value.isPlaying
                          ? _videoController!.pause()
                          : _videoController!.play();
                    });
                  },
                  child: Icon(
                    _videoController?.value.isPlaying == true
                        ? Icons.pause
                        : Icons.play_arrow,
                  ),
                )
                : null,
      ),
    );
  }
}
