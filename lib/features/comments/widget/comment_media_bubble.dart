import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/cache/utils/cloudinary_url_extensions.dart';
import 'package:video_player/video_player.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/core/widgets/cached_cloudinary_image.dart';
import 'package:social_media_app/features/comments/model/comment_model.dart';
import 'package:social_media_app/features/comments/model/comment_type.dart';
import 'package:social_media_app/features/comments/widget/comment_voice_player.dart';
import '../../../core/attachment/models/media_transfer_state.dart';
import '../../../core/attachment/utils/video_attachment_meta.dart';
import '../../../core/attachment/widgets/file_message_bubble.dart';
import '../../../core/attachment/widgets/media_download_gate.dart';
import '../../../core/attachment/widgets/media_loading_placeholder.dart';
import '../../../core/attachment/widgets/media_state_overlay.dart';
import '../../../core/widgets/video_progress_slider.dart';
import '../../gifs/utils/loop_limited_gif.dart';
import '../../single_chats/helper/glass_icon_btn.dart';
import '../../single_chats/widgets/full_screen_media_view.dart';
import '../../stickers/utils/animated_loop_cloudinary_sticker.dart';
import '../cubit/comments_cubit.dart';

class CommentMediaBubble extends StatelessWidget {
  final CommentModel comment;

  const CommentMediaBubble({super.key, required this.comment});

  @override
  Widget build(BuildContext context) {
    switch (comment.commentType) {
      case CommentType.image:
        return _ImageBubble(comment: comment);
      case CommentType.gif:
        return _GifBubble(comment: comment);
      case CommentType.sticker:
        return _StickerBubble(comment: comment);
      case CommentType.video:
        return _VideoBubble(comment: comment);
      case CommentType.voice:
        return _VoiceBubble(comment: comment);
      case CommentType.file:
        return comment.fileUrl == null
            ? const SizedBox.shrink()
            : FileMessageBubble(
              fileUrl: comment.fileUrl!,
              fileName: comment.fileName,
              fileSizeBytes: comment.fileSizeBytes,
            );
      case CommentType.text:
        return const SizedBox.shrink();
    }
  }
}

class _ImageBubble extends StatelessWidget {
  final CommentModel comment;
  const _ImageBubble({required this.comment});

  @override
  Widget build(BuildContext context) {
    if (comment.imageUrl == null) return const SizedBox.shrink();
    const size = 180.0;
    final bool isUploading = !comment.imageUrl!.startsWith('http');

    if (isUploading) {
      return ValueListenableBuilder<double>(
        valueListenable: context.read<CommentsCubit>().progressNotifierFor(
          comment.id,
        ),
        builder: (context, progress, _) {
          return MediaStateOverlay(
            state: MediaTransferState.uploading(progress),
            borderRadius: BorderRadius.circular(14),
            fileSizeBytes: comment.fileSizeBytes,
            onCancelTap: () => context.read<CommentsCubit>().cancelUpload(),
            child: Image.file(
              File(comment.imageUrl!),
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
          );
        },
      );
    }

    final heroTag = 'comment_${comment.id}';
    return MediaDownloadGate(
      secureUrl: comment.imageUrl!,
      fileSizeBytes: comment.fileSizeBytes,
      borderRadius: BorderRadius.circular(14),
      previewBuilder:
          (context) => CachedNetworkImage(
            imageUrl: comment.imageUrl!.cloudinaryLowResPreviewUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            placeholder:
                (context, _) =>
                    const MediaLoadingPlaceholder(width: size, height: size),
            errorWidget:
                (context, _, __) => const MediaLoadingPlaceholder(
                  width: size,
                  height: size,
                  isError: true,
                ),
          ),
      completedBuilder:
          (context, localPath) => GestureDetector(
            onTap: () {
              Navigator.of(context, rootNavigator: true).pushNamed(
                AppRoutes.fullScreenImageViewRoute,
                arguments: {
                  'url': comment.imageUrl,
                  'tag': heroTag,
                  'isAsset': false,
                  'caption': comment.text,
                },
              );
            },
            child: Hero(
              tag: heroTag,
              child: CachedCloudinaryImage(
                secureUrl: comment.imageUrl!,
                fit: BoxFit.cover,
                width: size,
                height: size,
                placeholder:
                    (context) => const MediaLoadingPlaceholder(
                      width: size,
                      height: size,
                    ),
              ),
            ),
          ),
    );
  }
}

class _GifBubble extends StatelessWidget {
  final CommentModel comment;
  const _GifBubble({required this.comment});

  @override
  Widget build(BuildContext context) {
    if (comment.imageUrl == null) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: LoopLimitedGif(
        url: comment.imageUrl!,
        width: 160,
        height: 160,
        fit: BoxFit.cover,
        maxLoops: 3,
      ),
    );
  }
}

class _StickerBubble extends StatelessWidget {
  final CommentModel comment;
  const _StickerBubble({required this.comment});

  @override
  Widget build(BuildContext context) {
    if (comment.imageUrl == null) return const SizedBox.shrink();
    return AnimatedLoopCloudinarySticker(
      secureUrl: comment.imageUrl!,
      maxLoops: 2,
      width: 140,
      height: 140,
    );
  }
}

class _VideoBubble extends StatefulWidget {
  final CommentModel comment;
  const _VideoBubble({required this.comment});

  @override
  State<_VideoBubble> createState() => _VideoBubbleState();
}

class _VideoBubbleState extends State<_VideoBubble> {
  File? _localThumbnail;
  late final bool _isUploading;

  @override
  void initState() {
    super.initState();
    _isUploading = !widget.comment.videoUrl!.startsWith('http');
    if (_isUploading) _loadLocalThumbnail();
  }

  Future<void> _loadLocalThumbnail() async {
    try {
      final meta = await extractVideoAttachmentMeta(
        File(widget.comment.videoUrl!),
      );
      if (mounted && meta.thumbnailFile != null) {
        setState(() => _localThumbnail = meta.thumbnailFile);
      }
    } catch (e) {
      debugPrint('[CommentMediaBubble] video thumbnail generation failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final comment = widget.comment;
    if (comment.videoUrl == null) return const SizedBox.shrink();
    const width = 180.0;
    const height = 185.0;

    if (_isUploading) {
      return ValueListenableBuilder<double>(
        valueListenable: context.read<CommentsCubit>().progressNotifierFor(
          comment.id,
        ),
        builder: (context, progress, _) {
          return MediaStateOverlay(
            state: MediaTransferState.uploading(progress),
            isVideo: true,
            borderRadius: BorderRadius.circular(14),
            fileSizeBytes: comment.fileSizeBytes,
            durationSeconds: comment.durationSeconds,
            onCancelTap: () => context.read<CommentsCubit>().cancelUpload(),
            child: SizedBox(
              width: width,
              height: height,
              child:
                  _localThumbnail != null
                      ? Image.file(_localThumbnail!, fit: BoxFit.cover)
                      : Container(color: Colors.grey.shade800),
            ),
          );
        },
      );
    }

    final thumbnailUrl = comment.videoUrl!.cloudinaryVideoThumbnailUrl;
    return MediaDownloadGate(
      secureUrl: comment.videoUrl!,
      isVideo: true,
      fileSizeBytes: comment.fileSizeBytes,
      durationSeconds: comment.durationSeconds,
      borderRadius: BorderRadius.circular(14),
      previewBuilder:
          (context) => SizedBox(
            width: width,
            height: height,
            child:
                thumbnailUrl != null
                    ? CachedCloudinaryImage(
                      secureUrl: thumbnailUrl,
                      fit: BoxFit.cover,
                      placeholder:
                          (context) => const MediaLoadingPlaceholder(
                            width: width,
                            height: height,
                          ),
                    )
                    : const MediaLoadingPlaceholder(
                      width: width,
                      height: height,
                    ),
          ),
      completedBuilder:
          (context, localPath) => _InlineVideoPlayer(
            localPath: localPath,
            caption: comment.text,
            width: width,
            height: height,
          ),
    );
  }
}

class _InlineVideoPlayer extends StatefulWidget {
  final String localPath;
  final String? caption;
  final double width;
  final double height;

  const _InlineVideoPlayer({
    required this.localPath,
    required this.caption,
    required this.width,
    required this.height,
  });

  @override
  State<_InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<_InlineVideoPlayer> {
  late final VideoPlayerController _controller;
  bool _isInitialized = false;

  bool _showControls = true;
  Timer? _hideTimer;
  double _lastVolume = 1.0;

  @override
  void initState() {
    super.initState();
    _controller =
        VideoPlayerController.file(File(widget.localPath))
          ..addListener(_onControllerUpdate)
          ..initialize().then((_) {
            if (!mounted) return;
            setState(() => _isInitialized = true);
            _startHideTimer();
          });
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = true;
    });
    _startHideTimer();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _showControls = true;
        _hideTimer?.cancel();
      } else {
        if (_controller.value.position >= _controller.value.duration) {
          _controller.seekTo(Duration.zero);
        }
        _controller.play();
        _startHideTimer();
      }
    });
  }

  void _toggleMute() {
    setState(() {
      if (_controller.value.volume > 0) {
        _lastVolume = _controller.value.volume;
        _controller.setVolume(0);
      } else {
        _controller.setVolume(_lastVolume > 0 ? _lastVolume : 1.0);
      }
    });
    _toggleControls();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _openFullScreen() {
    _hideTimer?.cancel();
    Navigator.of(context, rootNavigator: true)
        .push(
          PageRouteBuilder(
            opaque: false,
            pageBuilder:
                (_, __, ___) => FullScreenMediaView(
                  videoUrl: widget.localPath,
                  isLocal: true,
                  caption: widget.caption,
                  controller: _controller,
                ),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        )
        .then((_) {
          if (mounted) {
            setState(() {
              _showControls = true;
            });
            if (_controller.value.isPlaying) {
              _startHideTimer();
            }
          }
        });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: GestureDetector(
        onTap: () {
          if (!_controller.value.isPlaying) {
            _togglePlayPause();
          } else if (!_showControls) {
            _toggleControls();
          } else {
            _togglePlayPause();
          }
        },
        onDoubleTap: _openFullScreen,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_isInitialized)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              )
            else
              MediaLoadingPlaceholder(
                width: widget.width,
                height: widget.height,
              ),

            AnimatedOpacity(
              opacity:
                  _showControls || !_controller.value.isPlaying ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: Colors.black.withValues(alpha: 0.2)),

                  if (!_controller.value.isPlaying)
                    const Center(
                      child: Icon(
                        Icons.play_circle_fill_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),

                  Positioned(
                    top: 6,
                    left: 6,
                    child: GlassIconButton(
                      size: 28,
                      iconSize: 14,
                      icon:
                          _controller.value.volume > 0
                              ? Icons.volume_up_rounded
                              : Icons.volume_off_rounded,
                      onTap: _toggleMute,
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GlassIconButton(
                      size: 28,
                      iconSize: 14,
                      icon: Icons.aspect_ratio,
                      onTap: _openFullScreen,
                    ),
                  ),

                  if (_isInitialized)
                    Positioned(
                      bottom: 6,
                      left: 8,
                      right: 8,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: VideoProgressSlider(
                              controller: _controller,
                              trackHeight: 3,
                              thumbSize: 9,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            (_controller.value.position == Duration.zero &&
                                    !_controller.value.isPlaying)
                                ? _formatDuration(_controller.value.duration)
                                : _formatDuration(_controller.value.position),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              shadows: [
                                Shadow(color: Colors.black87, blurRadius: 3),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceBubble extends StatelessWidget {
  final CommentModel comment;
  const _VoiceBubble({required this.comment});

  @override
  Widget build(BuildContext context) {
    if (comment.voiceUrl == null) return const SizedBox.shrink();
    return CommentVoicePlayer(
      source: comment.voiceUrl!,
      durationSeconds: comment.durationSeconds,
      showBubbleBackground: true,
    );
  }
}
