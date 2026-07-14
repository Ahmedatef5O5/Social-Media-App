import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import 'package:social_media_app/core/helpers/media_duration_badge.dart';
import 'package:social_media_app/core/helpers/modern_circle_progress.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import 'package:social_media_app/features/comments/cubit/comments_cubit.dart';
import 'package:social_media_app/features/comments/model/comment_attachment_draft.dart';
import 'package:social_media_app/features/comments/model/comment_type.dart';
import 'package:social_media_app/features/comments/widget/comment_voice_player.dart';
import '../../../core/router/app_routes.dart';
import '../../single_chats/widgets/full_screen_media_view.dart';

class CommentAttachmentPreview extends StatelessWidget {
  const CommentAttachmentPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<CommentsCubit>();
    final attachment = cubit.pendingAttachment;
    if (attachment == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _PreviewThumbnail(attachment: attachment),
          const SizedBox(width: 12),
          Expanded(child: _PreviewInfo(attachment: attachment)),
          if (cubit.isUploading)
            SizedBox(
              width: 28,
              height: 28,
              child: ModernCircularProgress(
                progress: cubit.uploadProgress,
                size: 28,
                label: '',
              ),
            )
          else
            InkWell(
              onTap: () => context.read<CommentsCubit>().clearAttachment(),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.grey5.withValues(alpha: 0.3),
                child: const Icon(Icons.close_rounded, size: 16),
              ),
            ),
        ],
      ),
    );
  }
}

class _PreviewThumbnail extends StatelessWidget {
  final CommentAttachmentDraft attachment;
  const _PreviewThumbnail({required this.attachment});

  @override
  Widget build(BuildContext context) {
    const size = 52.0;

    switch (attachment.type) {
      case CommentType.image:
        final heroTag = 'attachment_preview_${attachment.localFile!.path}';

        return GestureDetector(
          onTap: () {
            Navigator.of(context, rootNavigator: true).pushNamed(
              AppRoutes.fullScreenImageViewRoute,
              arguments: {
                'url': attachment.localFile!.path,
                'tag': heroTag,
                'isAsset': false,
                'isLocalFile': true,
              },
            );
          },
          child: Hero(
            tag: heroTag,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                attachment.localFile!,
                width: size,
                height: size,
                fit: BoxFit.cover,
              ),
            ),
          ),
        );

      case CommentType.video:
        return GestureDetector(
          onTap: () {
            final videoPath =
                attachment.localFile?.path ?? attachment.remoteUrl;
            if (videoPath != null) {
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder:
                      (_) => FullScreenMediaView(
                        videoUrl: videoPath,
                        isLocal: attachment.localFile != null,
                      ),
                ),
              );
            }
          },
          child: _VideoThumbnail(file: attachment.localFile!, size: size),
        );

      case CommentType.gif:
      case CommentType.sticker:
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            attachment.remoteUrl!,
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        );

      case CommentType.voice:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.mic_rounded, color: Colors.orange),
        );

      case CommentType.file:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.blueAccent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.insert_drive_file_rounded,
            color: Colors.blueAccent,
          ),
        );

      case CommentType.text:
        return const SizedBox.shrink();
    }
  }
}

class _VideoThumbnail extends StatefulWidget {
  final File file;
  final double size;
  const _VideoThumbnail({required this.file, required this.size});

  @override
  State<_VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<_VideoThumbnail> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    final controller = VideoPlayerController.file(widget.file);
    _controller = controller;
    controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
      context.read<CommentsCubit>().updateAttachmentDuration(
        controller.value.duration.inSeconds,
      );
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (controller != null && controller.value.isInitialized)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              )
            else
              Container(color: AppColors.grey5.withValues(alpha: 0.2)),
            const Center(
              child: Icon(
                Icons.play_circle_fill_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewInfo extends StatelessWidget {
  final CommentAttachmentDraft attachment;
  const _PreviewInfo({required this.attachment});

  String _formatSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    switch (attachment.type) {
      case CommentType.voice:
        return attachment.localFile != null
            ? CommentVoicePlayer(
              source: attachment.localFile!.path,
              isLocalFile: true,
              durationSeconds: attachment.durationSeconds,
            )
            : const SizedBox.shrink();

      case CommentType.file:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              attachment.fileName ?? 'File',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              _formatSize(attachment.fileSizeBytes),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.grey6,
              ),
            ),
          ],
        );

      case CommentType.image:
        return Text(
          'Photo',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        );

      case CommentType.video:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Video',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            MediaDurationBadge(seconds: attachment.durationSeconds),
          ],
        );

      case CommentType.gif:
        return Text(
          'GIF',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        );

      case CommentType.sticker:
        return Text(
          'Sticker',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        );

      case CommentType.text:
        return const SizedBox.shrink();
    }
  }
}
