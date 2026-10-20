import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:video_player/video_player.dart';
import '../../../core/media_editor/media_editor_service.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../../../core/widgets/directional_text_field.dart';
import '../../ai_assistant/entities/ai_action_type.dart';
import '../../ai_assistant/entities/ai_request_context.dart';
import '../../ai_assistant/widgets/ai_action_icon.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

class GroupMediaPreviewScreen extends StatefulWidget {
  final File file;
  final String type;

  /// Called with the caption, the file that should actually be sent (the
  /// original, or the edited / trimmed copy) and — for videos — its duration.
  final Function(String? caption, File file, int? durationSeconds) onSend;

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
    _videoCtrl = controller;
    controller.initialize().then((_) {
      if (!mounted || _videoCtrl != controller) return;
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
      await _videoCtrl?.pause();
      if (!mounted) return;
      final trimmed = await MediaEditorService.trimVideo(context, _file);
      if (trimmed == null || !mounted) return;
      final old = _videoCtrl;
      setState(() {
        _videoCtrl = null;
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
            IconButton(
              tooltip:
                  widget.type == 'video'
                      ? context.l10n.trim
                      : context.l10n.edit,
              icon: Icon(
                widget.type == 'video'
                    ? Icons.content_cut_rounded
                    : Icons.edit_rounded,
                color: Colors.white,
              ),
              onPressed: _editMedia,
            ),
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
                        ? Image.file(_file, fit: BoxFit.contain)
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
                          hintText: context.l10n.addACaption2,
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
                                    ? () => _file.readAsBytes()
                                    : null,
                          ),
                        ),
                      ),
                    ),
                    const Gap(8),
                    GestureDetector(
                      onTap: () {
                        final caption = _captionController.text.trim();
                        final controller = _videoCtrl;
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
