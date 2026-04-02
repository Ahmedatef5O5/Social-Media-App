import 'package:chewie/chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import 'package:video_player/video_player.dart';
import '../../../core/widgets/custom_loading_indicator.dart';

class PostVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const PostVideoPlayer({super.key, required this.videoUrl});

  @override
  State<PostVideoPlayer> createState() => _PostVideoPlayerState();
}

class _PostVideoPlayerState extends State<PostVideoPlayer> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );
    try {
      await _videoPlayerController.initialize();
      if (!mounted) return;
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: false,
        looping: false,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        placeholder: Container(color: AppColors.grey4.withValues(alpha: 0.2)),
        errorBuilder:
            (context, errorMessage) => Center(
              child: Text(
                errorMessage,
                style: const TextStyle(color: AppColors.white),
              ),
            ),
      );
      setState(() {});
    } catch (e) {
      debugPrint('Video initialization failed: $e');
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.grey4.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child:
          _chewieController != null &&
                  _chewieController!.videoPlayerController.value.isInitialized
              ? ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Chewie(controller: _chewieController!),
              )
              : Center(child: const CustomLoadingIndicator()),
    );
  }
}
