import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:video_player/video_player.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../../../core/widgets/directional_text_field.dart';
import '../../ai_assistant/entities/ai_action_type.dart';
import '../../ai_assistant/entities/ai_request_context.dart';
import '../../ai_assistant/widgets/ai_action_icon.dart';

class GroupMediaPreviewScreen extends StatefulWidget {
  final File file;
  final String type;
  final Function(String? caption) onSend;

  const GroupMediaPreviewScreen({
    super.key,
    required this.file,
    required this.type,
    required this.onSend,
  });

  @override
  State<GroupMediaPreviewScreen> createState() =>
      _GroupMediaPreviewScreenState();
}

class _GroupMediaPreviewScreenState extends State<GroupMediaPreviewScreen> {
  final _captionController = TextEditingController();
  VideoPlayerController? _videoCtrl;

  bool _showControls = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    if (widget.type == 'video') {
      _videoCtrl = VideoPlayerController.file(widget.file)
        ..initialize().then((_) {
          setState(() {});
          _videoCtrl!.play();
          _videoCtrl!.setLooping(true);
          _startHideTimer();
        });
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _videoCtrl?.dispose();
    _captionController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && (_videoCtrl?.value.isPlaying ?? false)) {
        setState(() => _showControls = false);
      }
    });
  }

  void _togglePlayPause() {
    if (_videoCtrl == null) return;

    setState(() {
      if (_videoCtrl!.value.isPlaying) {
        _videoCtrl!.pause();
        _showControls = true;
        _hideTimer?.cancel();
      } else {
        _videoCtrl!.play();
        _startHideTimer();
      }
    });
  }

  Widget _buildVideoControls() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() => _showControls = !_showControls);
        if (_showControls) _startHideTimer();
      },
      child: AnimatedOpacity(
        opacity: _showControls ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(color: Colors.black26),

            GestureDetector(
              onTap: _togglePlayPause,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _videoCtrl!.value.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
            ),

            Positioned(
              bottom: -8,
              left: 20,
              right: 20,
              child: VideoProgressIndicator(
                _videoCtrl!,
                allowScrubbing: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                colors: VideoProgressColors(
                  playedColor: Theme.of(context).primaryColor,
                  bufferedColor: Colors.white54,
                  backgroundColor: Colors.white24,
                ),
              ),
            ),
          ],
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
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            if (widget.type == 'video' &&
                _videoCtrl != null &&
                _videoCtrl!.value.isInitialized)
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.videocam_outlined,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(_videoCtrl!.value.duration),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Center(
                child:
                    widget.type == 'image'
                        ? Image.file(widget.file, fit: BoxFit.contain)
                        : _videoCtrl != null && _videoCtrl!.value.isInitialized
                        ? AspectRatio(
                          aspectRatio: _videoCtrl!.value.aspectRatio,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              VideoPlayer(_videoCtrl!),
                              _buildVideoControls(),
                            ],
                          ),
                        )
                        : const CustomLoadingIndicator(color: Colors.white),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              color: Colors.black54,
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: DirectionalTextField(
                        controller: _captionController,
                        style: const TextStyle(color: Colors.white),
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Add a caption…',
                          hintStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: Colors.white12,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          suffixIcon: AiActionIcon(
                            controller: _captionController,
                            surface: AiSurfaceType.chatMessage,
                            generationAction: AiActionType.autocompleteCaption,
                            actionContext: AiActionContext.mediaCaption,
                            hasMediaAttached: true,
                            targetMediaType:
                                widget.type == 'image'
                                    ? AiTargetMediaType.image
                                    : AiTargetMediaType.video,
                            imageBytesProvider:
                                widget.type == 'image'
                                    ? () => widget.file.readAsBytes()
                                    : null,
                          ),
                        ),
                      ),
                    ),
                    const Gap(8),
                    GestureDetector(
                      onTap: () {
                        final caption = _captionController.text.trim();
                        Navigator.pop(context);
                        widget.onSend(caption.isEmpty ? null : caption);
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                        ),
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
