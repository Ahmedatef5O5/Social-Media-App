import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:social_media_app/core/cache/utils/cloudinary_url_extensions.dart';
import 'package:video_player/video_player.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/core/widgets/cached_cloudinary_image.dart';
import 'package:social_media_app/features/comments/model/comment_model.dart';
import 'package:social_media_app/features/comments/model/comment_type.dart';
import 'package:social_media_app/features/comments/widget/comment_voice_player.dart';
import '../../../core/attachment/widgets/file_message_bubble.dart';
import '../../../core/attachment/widgets/media_download_gate.dart';
import '../../../core/widgets/video_progress_slider.dart';
import '../../gifs/utils/loop_limited_gif.dart';
import '../../single_chats/helper/glass_icon_btn.dart';
import '../../single_chats/widgets/full_screen_media_view.dart';
import '../../stickers/utils/animated_loop_cloudinary_sticker.dart';

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

class _MediaLoadingPlaceholder extends StatelessWidget {
  final double width;
  final double height;
  const _MediaLoadingPlaceholder({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(width: width, height: height, color: Colors.white),
    );
  }
}

class _ImageBubble extends StatelessWidget {
  final CommentModel comment;
  const _ImageBubble({required this.comment});

  @override
  Widget build(BuildContext context) {
    if (comment.imageUrl == null) return const SizedBox.shrink();
    final heroTag = 'comment_${comment.id}';
    const size = 180.0;

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
                    const _MediaLoadingPlaceholder(width: size, height: size),
            errorWidget:
                (context, _, __) =>
                    const _MediaLoadingPlaceholder(width: size, height: size),
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
                    (context) => const _MediaLoadingPlaceholder(
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

class _VideoBubble extends StatelessWidget {
  final CommentModel comment;
  const _VideoBubble({required this.comment});

  @override
  Widget build(BuildContext context) {
    if (comment.videoUrl == null) return const SizedBox.shrink();
    const width = 180.0;
    const height = 185.0;
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
                          (context) => const _MediaLoadingPlaceholder(
                            width: width,
                            height: height,
                          ),
                    )
                    : const _MediaLoadingPlaceholder(
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

  @override
  void initState() {
    super.initState();
    _controller =
        VideoPlayerController.file(File(widget.localPath))
          ..addListener(_onControllerUpdate)
          ..initialize().then((_) {
            if (!mounted) return;
            setState(() => _isInitialized = true);
          });
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  void _openFullScreen() {
    Navigator.of(context, rootNavigator: true)
        .push(
          MaterialPageRoute(
            builder:
                (_) => FullScreenMediaView(
                  videoUrl: widget.localPath,
                  isLocal: true,
                  caption: widget.caption,
                  controller: _controller,
                ),
          ),
        )
        .then((_) {
          if (mounted) setState(() {});
        });
  }

  @override
  void dispose() {
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
          setState(() {
            _controller.value.isPlaying
                ? _controller.pause()
                : _controller.play();
          });
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
              _MediaLoadingPlaceholder(
                width: widget.width,
                height: widget.height,
              ),
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
                bottom: 4,
                left: 6,
                right: 6,
                child: VideoProgressSlider(
                  controller: _controller,
                  trackHeight: 3,
                  thumbSize: 9,
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
