import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import 'package:video_player/video_player.dart';
import '../../../core/themes/app_colors.dart';

class VoiceMessageBubbleWidget extends StatefulWidget {
  final String voiceUrl;
  final bool isMe;

  const VoiceMessageBubbleWidget({
    super.key,
    required this.voiceUrl,
    required this.isMe,
  });

  @override
  State<VoiceMessageBubbleWidget> createState() =>
      _VoiceMessageBubbleWidgetState();
}

class _VoiceMessageBubbleWidgetState extends State<VoiceMessageBubbleWidget> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  bool _isInitialized = false;
  bool _isLoading = false;

  Future<void> _initAndPlay() async {
    if (_isInitialized) {
      setState(() {
        _isPlaying = !_isPlaying;
        _isPlaying ? _controller!.play() : _controller!.pause();
      });
      return;
    }
    setState(() => _isLoading = true);

    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.voiceUrl));
    await _controller!.initialize();

    _controller!.addListener(() {
      if (_controller!.value.position >= _controller!.value.duration &&
          _controller!.value.duration.inSeconds > 0) {
        setState(() => _isPlaying = false);
        _controller!.seekTo(Duration.zero);
      }
    });

    await _controller!.play();
    setState(() {
      _isInitialized = true;
      _isLoading = false;
      _isPlaying = true;
    });
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _controller?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          onPressed: _isLoading ? null : _initAndPlay,

          icon:
              _isLoading
                  ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CustomLoadingIndicator(
                      color:
                          widget.isMe
                              ? AppColors.white
                              : AppColors.primaryColor,
                    ),
                  )
                  : Icon(
                    _isPlaying ? Icons.pause_circle : Icons.play_circle,
                    color:
                        widget.isMe ? AppColors.white : AppColors.primaryColor,
                    size: 32,
                  ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isInitialized)
                VideoProgressIndicator(
                  _controller!,
                  allowScrubbing: true,
                  colors: VideoProgressColors(
                    playedColor:
                        widget.isMe ? AppColors.white : AppColors.primaryColor,
                    bufferedColor: Colors.white38,
                    backgroundColor: Colors.white24,
                  ),
                )
              else
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

              const Gap(4),
              Text(
                _isInitialized
                    ? _formatDuration(_controller!.value.duration)
                    : '--:--',
                style: TextStyle(
                  color: widget.isMe ? AppColors.white70 : AppColors.black54,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const Gap(8),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
