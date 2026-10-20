import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import 'package:video_player/video_player.dart';
import '../../../core/media_editor/media_editor_service.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/directional_text_field.dart';
import '../../ai_assistant/entities/ai_action_type.dart';
import '../../ai_assistant/entities/ai_request_context.dart';
import '../../ai_assistant/widgets/ai_action_icon.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

class MediaPreviewScreen extends StatefulWidget {
  final File file;
  final String type;

  /// Called with the caption, the file that should actually be sent (the
  /// original, or the edited / trimmed copy) and — for videos — its duration.
  final Function(String? caption, File file, int? durationSeconds) onSend;

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

  /// Starts as the picked media; replaced if the user edits / trims it.
  late File _file = widget.file;

  bool _showControls = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    if (widget.type == 'video') _initVideo();
  }

  void _initVideo() {
    final controller = VideoPlayerController.file(_file);
    _videoPlayerController = controller;
    controller.initialize().then((_) {
      if (!mounted || _videoPlayerController != controller) return;
      setState(() {});
      controller.play();
      controller.setLooping(true);
      _startHideTimer();
    });
  }

  /// Optional edit: crop/draw/text/stickers for photos, trim for videos.
  Future<void> _editMedia() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (widget.type == 'video') {
      await _videoPlayerController?.pause();
      if (!mounted) return;
      final trimmed = await MediaEditorService.trimVideo(context, _file);
      if (trimmed == null || !mounted) return;
      final old = _videoPlayerController;
      setState(() {
        _videoPlayerController = null;
        _file = trimmed.file;
      });
      await old?.dispose();
      _initVideo();
    } else {
      final edited = await MediaEditorService.editImage(
        context,
        _file,
        preset: MediaEditorPreset.chat,
      );
      if (edited == null || !mounted) return;
      setState(() => _file = edited);
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _videoPlayerController?.dispose();
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
      if (mounted && (_videoPlayerController?.value.isPlaying ?? false)) {
        setState(() => _showControls = false);
      }
    });
  }

  void _togglePlayPause() {
    if (_videoPlayerController == null) return;

    setState(() {
      if (_videoPlayerController!.value.isPlaying) {
        _videoPlayerController!.pause();
        _showControls = true;
        _hideTimer?.cancel();
      } else {
        _videoPlayerController!.play();
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
                  _videoPlayerController!.value.isPlaying
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
                _videoPlayerController!,
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
        backgroundColor: AppColors.black,
        appBar: AppBar(
          backgroundColor: AppColors.black,
          iconTheme: const IconThemeData(color: AppColors.white),
          actions: [
            IconButton(
              tooltip:
                  widget.type == 'video'
                      ? context.l10n.trim
                      : context.l10n.edit,
              icon: Icon(
                widget.type == 'video'
                    ? Icons.content_cut_rounded
                    : Icons.edit_rounded,
                color: AppColors.white,
              ),
              onPressed: _editMedia,
            ),
            if (widget.type == 'video' &&
                _videoPlayerController != null &&
                _videoPlayerController!.value.isInitialized)
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
                          _formatDuration(
                            _videoPlayerController!.value.duration,
                          ),
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
                        ? Image.file(_file, fit: BoxFit.contain)
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
                      child: DirectionalTextField(
                        controller: _captionController,
                        style: const TextStyle(color: AppColors.white),
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: context.l10n.addAnOptionalCaption,
                          hintStyle: const TextStyle(color: AppColors.white60),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          fillColor: Colors.white30,
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                          ),
                          suffixIcon: AiActionIcon(
                            controller: _captionController,
                            surface: AiSurfaceType.chatMessage,
                            actionContext: AiActionContext.mediaCaption,
                            generationAction: AiActionType.autocompleteCaption,
                            hasMediaAttached: true,
                            targetMediaType:
                                widget.type == 'image'
                                    ? AiTargetMediaType.image
                                    : AiTargetMediaType.video,
                            imageBytesProvider:
                                widget.type == 'image'
                                    ? () => _file.readAsBytes()
                                    : null,
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
                          final caption = _captionController.text.trim();
                          final controller = _videoPlayerController;
                          final int? durationSeconds =
                              widget.type == 'video' &&
                                      controller != null &&
                                      controller.value.isInitialized
                                  ? controller.value.duration.inSeconds
                                  : null;
                          Navigator.pop(context);
                          widget.onSend(
                            caption.isEmpty ? null : caption,
                            _file,
                            durationSeconds,
                          );
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
