import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:social_media_app/core/cache/utils/cloudinary_url_extensions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:social_media_app/core/helpers/media_duration_badge.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import 'package:social_media_app/core/widgets/cached_cloudinary_image.dart';
import 'package:social_media_app/features/comments/model/comment_model.dart';
import 'package:social_media_app/features/comments/model/comment_type.dart';
import 'package:social_media_app/features/comments/widget/comment_voice_player.dart';
import '../../gifs/utils/loop_limited_gif.dart';
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
        return _FileBubble(comment: comment);
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
    return GestureDetector(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Hero(
          tag: heroTag,
          child: CachedCloudinaryImage(
            secureUrl: comment.imageUrl!,
            fit: BoxFit.cover,
            width: 180,
            height: 180,
            placeholder:
                (context) =>
                    const _MediaLoadingPlaceholder(width: 180, height: 180),
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
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  void _initAndPlay() {
    if (widget.comment.videoUrl == null) return;
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.comment.videoUrl!),
    );
    _controller = controller;
    controller.initialize().then((_) {
      if (!mounted) return;
      setState(() => _isInitialized = true);
      controller
        ..play()
        ..setLooping(false);
      controller.addListener(() {
        if (mounted) setState(() {});
      });
    });
  }

  void _openFullScreen() {
    if (widget.comment.videoUrl == null) return;

    Navigator.of(context, rootNavigator: true)
        .push(
          MaterialPageRoute(
            builder:
                (_) => FullScreenMediaView(
                  videoUrl: widget.comment.videoUrl,
                  caption: widget.comment.text,
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
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.comment.videoUrl == null) return const SizedBox.shrink();
    final String? thumbnailUrl =
        widget.comment.videoUrl!.cloudinaryVideoThumbnailUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 180,
        height: 185,
        child: GestureDetector(
          onTap: () {
            if (_controller == null) {
              setState(_initAndPlay);
            } else {
              setState(() {
                _controller!.value.isPlaying
                    ? _controller!.pause()
                    : _controller!.play();
              });
            }
          },
          onDoubleTap: _openFullScreen,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_isInitialized && _controller != null)
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller!.value.size.width,
                    height: _controller!.value.size.height,
                    child: VideoPlayer(_controller!),
                  ),
                )
              else
                CachedCloudinaryImage(
                  secureUrl: thumbnailUrl ?? widget.comment.videoUrl!,
                  fit: BoxFit.cover,
                  placeholder:
                      (context) => const _MediaLoadingPlaceholder(
                        width: 180,
                        height: 185,
                      ),
                ),
              if (_controller == null || !_controller!.value.isPlaying)
                const Center(
                  child: Icon(
                    Icons.play_circle_fill_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              if (!_isInitialized)
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: MediaDurationBadge(
                    seconds: widget.comment.durationSeconds,
                  ),
                ),
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: _openFullScreen,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.aspect_ratio,
                      // Icons.fullscreen,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),

              // --- 5. شريط التقدم (Progress Bar) ---
              if (_isInitialized && _controller != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: VideoProgressIndicator(
                    _controller!,
                    allowScrubbing: true,
                    colors: VideoProgressColors(
                      playedColor: Theme.of(context).primaryColor,
                      backgroundColor: Colors.transparent,
                      bufferedColor: Colors.white38,
                    ),
                  ),
                ),
            ],
          ),
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

class _FileBubble extends StatelessWidget {
  final CommentModel comment;
  const _FileBubble({required this.comment});

  String _formatSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    if (comment.fileUrl == null) return const SizedBox.shrink();
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap:
          () => launchUrl(
            Uri.parse(comment.fileUrl!),
            mode: LaunchMode.externalApplication,
          ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.insert_drive_file_rounded,
              color: Colors.blueAccent,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    comment.fileName ?? 'File',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _formatSize(comment.fileSizeBytes),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.grey6,
                      fontSize: 10,
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
