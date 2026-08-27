import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:social_media_app/core/helpers/chat_helper.dart';
import 'package:social_media_app/core/helpers/media_duration_badge.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import 'package:social_media_app/features/comments/cubit/comments_cubit.dart';
import 'package:social_media_app/features/comments/model/comment_attachment_draft.dart';
import 'package:social_media_app/features/comments/model/comment_type.dart';
import 'package:social_media_app/features/comments/widget/comment_voice_player.dart';
import '../../../core/attachment/widgets/transfer_ring.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utilities/file_size_formatter.dart';
import '../../single_chats/widgets/full_screen_media_view.dart';

class CommentAttachmentPreview extends StatelessWidget {
  const CommentAttachmentPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<CommentsCubit>();
    final attachment = cubit.pendingAttachment;
    if (attachment == null) return const SizedBox.shrink();
    final isOptimisticMedia =
        attachment.type == CommentType.video ||
        attachment.type == CommentType.image;

    if (cubit.isUploading && isOptimisticMedia) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _PreviewThumbnail(attachment: attachment),
          const SizedBox(width: 10),
          Expanded(
            child: _PreviewInfo(
              attachment: attachment,
              isUploading: cubit.isUploading,
            ),
          ),
          const SizedBox(width: 8),
          if (cubit.isUploading)
            _CompactUploadProgress(
              progress: cubit.uploadProgress,
              fileSizeBytes: attachment.fileSizeBytes,
              durationSeconds: attachment.durationSeconds,
              isVideo: attachment.type == CommentType.video,
              onCancel: () => context.read<CommentsCubit>().cancelUpload(),
            )
          else
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => context.read<CommentsCubit>().clearAttachment(),
              child: CircleAvatar(
                radius: 13,
                backgroundColor: AppColors.grey5.withValues(alpha: 0.3),
                child: const Icon(Icons.close_rounded, size: 15),
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

  String _getFileExtension() {
    final name = attachment.fileName ?? attachment.localFile?.path ?? '';
    if (name.contains('.')) {
      return name.substring(name.lastIndexOf('.') + 1).toUpperCase();
    }
    return 'FILE';
  }

  (FaIconData, Color) _getFileIconAndColor(String ext, Color defaultColor) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return (FontAwesomeIcons.solidFilePdf, const Color(0xFFE5252A));
      case 'doc':
      case 'docx':
        return (FontAwesomeIcons.solidFileWord, const Color(0xFF185ABD));
      case 'xls':
      case 'xlsx':
      case 'csv':
        return (FontAwesomeIcons.solidFileExcel, const Color(0xFF217346));
      case 'ppt':
      case 'pptx':
        return (FontAwesomeIcons.solidFilePowerpoint, const Color(0xFFD24726));
      case 'txt':
      case 'rtf':
        return (FontAwesomeIcons.solidFileLines, const Color(0xFF2E7D52));
      case 'md':
        return (FontAwesomeIcons.solidFileLines, const Color(0xFF3B82F6));
      case 'json':
      case 'dart':
      case 'py':
      case 'pyw':
      case 'js':
      case 'ts':
      case 'html':
      case 'htm':
      case 'css':
      case 'xml':
      case 'yaml':
      case 'yml':
      case 'java':
      case 'kt':
      case 'kts':
      case 'c':
      case 'cpp':
      case 'cc':
      case 'cxx':
      case 'h':
      case 'hpp':
      case 'cs':
      case 'swift':
      case 'go':
      case 'rb':
      case 'rs':
      case 'sql':
      case 'sh':
      case 'bat':
      case 'env':
        return (FontAwesomeIcons.solidFileCode, const Color(0xFF00B4D8));
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return (FontAwesomeIcons.solidFileZipper, const Color(0xFFF59E0B));
      case 'mp3':
      case 'wav':
      case 'm4a':
      case 'aac':
      case 'ogg':
        return (FontAwesomeIcons.solidFileAudio, const Color(0xFF9333EA));
      case 'mp4':
      case 'avi':
      case 'mkv':
      case 'mov':
        return (FontAwesomeIcons.solidFileVideo, const Color(0xFFE11D48));
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'webp':
        return (FontAwesomeIcons.solidFileImage, const Color(0xFF059669));
      default:
        return (FontAwesomeIcons.solidFile, defaultColor);
    }
  }

  @override
  Widget build(BuildContext context) {
    const size = 44.0;
    final primary = Theme.of(context).primaryColor;

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
              borderRadius: BorderRadius.circular(10),
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
                PageRouteBuilder(
                  opaque: false,
                  pageBuilder:
                      (_, __, ___) => FullScreenMediaView(
                        videoUrl: videoPath,
                        isLocal: attachment.localFile != null,
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
              );
            }
          },
          child: _VideoThumbnail(file: attachment.localFile!, size: size),
        );

      case CommentType.gif:
      case CommentType.sticker:
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
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
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.mic_rounded, color: Colors.orange, size: 22),
        );

      case CommentType.file:
        final ext = _getFileExtension();
        final (fileIcon, iconAccent) = _getFileIconAndColor(ext, primary);
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: FaIcon(fileIcon, color: iconAccent, size: 22),
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
      borderRadius: BorderRadius.circular(10),
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
                size: 20,
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
  final bool isUploading;
  const _PreviewInfo({required this.attachment, this.isUploading = false});

  String _getFileExtension() {
    final name = attachment.fileName ?? attachment.localFile?.path ?? '';
    if (name.contains('.')) {
      return name.substring(name.lastIndexOf('.') + 1).toUpperCase();
    }
    return 'FILE';
  }

  String _formatSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    switch (attachment.type) {
      case CommentType.voice:
        if (isUploading) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MediaDurationBadge(
                seconds: attachment.durationSeconds,
                fontSize: 7.8,
              ),
              const SizedBox(width: 4),
              Text(
                '🎤 voice',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        }
        return attachment.localFile != null
            ? CommentVoicePlayer(
              source: attachment.localFile!.path,
              isLocalFile: true,
              durationSeconds: attachment.durationSeconds,
            )
            : const SizedBox.shrink();

      case CommentType.file:
        final fileName =
            attachment.fileName?.trim().isNotEmpty == true
                ? attachment.fileName!
                : 'File';
        final ext = _getFileExtension();
        final sizeStr = _formatSize(attachment.fileSizeBytes);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: ChatHelper.getTextDirection(fileName),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(
                      alpha: isDark ? 0.25 : 0.12,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    ext,
                    style: TextStyle(
                      color: isDark ? Colors.white : theme.primaryColor,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                if (sizeStr.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    sizeStr,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.white70 : AppColors.grey6,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
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

class _CompactUploadProgress extends StatelessWidget {
  final double progress;
  final int? fileSizeBytes;
  final int? durationSeconds;
  final bool isVideo;
  final VoidCallback onCancel;

  const _CompactUploadProgress({
    required this.progress,
    required this.fileSizeBytes,
    required this.durationSeconds,
    required this.isVideo,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final ratioText = formatMediaFileSizeRatio(
      ((fileSizeBytes ?? 0) * progress).round(),
      fileSizeBytes,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TransferRing(
            size: 24,
            progress: progress,
            icon: Icons.close_rounded,
            iconColor: Colors.red.shade400,
            onTap: onCancel,
          ),
          const SizedBox(width: 5),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isVideo && durationSeconds != null)
                Text(
                  formatMediaDuration(durationSeconds!),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              Text(
                ratioText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
