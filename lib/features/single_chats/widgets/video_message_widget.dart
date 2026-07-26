import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/core/attachment/widgets/media_download_gate.dart';
import 'package:social_media_app/core/cache/utils/cloudinary_url_extensions.dart';
import 'package:social_media_app/features/single_chats/widgets/full_screen_media_view.dart';
import '../../../core/attachment/utils/video_attachment_meta.dart';
import '../../../core/themes/app_colors.dart';

class VideoMessageWidget extends StatefulWidget {
  final String videoUrl;
  final String? caption;
  final bool isMe;
  final int? fileSizeBytes;
  final int? durationSeconds;

  const VideoMessageWidget({
    super.key,
    required this.videoUrl,
    this.caption,
    required this.isMe,
    this.fileSizeBytes,
    this.durationSeconds,
  });

  @override
  State<VideoMessageWidget> createState() => _VideoMessageWidgetState();
}

class _VideoMessageWidgetState extends State<VideoMessageWidget> {
  File? _localThumbnail;
  late bool _isLocal;

  @override
  void initState() {
    super.initState();
    _isLocal = !widget.videoUrl.startsWith('http');

    if (_isLocal) {
      _loadLocalThumbnail();
    }
  }

  Future<void> _loadLocalThumbnail() async {
    try {
      final meta = await extractVideoAttachmentMeta(File(widget.videoUrl));
      if (mounted && meta.thumbnailFile != null) {
        setState(() {
          _localThumbnail = meta.thumbnailFile;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(15),
      topRight: const Radius.circular(15),
      bottomRight: Radius.circular(widget.isMe ? 0 : 15),
      bottomLeft: Radius.circular(widget.isMe ? 15 : 0),
    );

    final thumbnailUrl =
        _isLocal ? null : widget.videoUrl.cloudinaryVideoThumbnailUrl;

    Widget frame(Widget content, {bool showPlay = false}) => Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(
          color:
              isDarkMode
                  ? Colors.white.withValues(alpha: 0.1)
                  : AppColors.grey.withValues(alpha: 0.12),
          width: 1.8,
        ),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_isLocal && _localThumbnail != null)
              Image.file(_localThumbnail!, fit: BoxFit.cover)
            else if (!_isLocal && thumbnailUrl != null)
              CachedNetworkImage(imageUrl: thumbnailUrl, fit: BoxFit.cover)
            else
              Container(color: Colors.grey.shade800),

            content,

            if (showPlay)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.scaffoldBackgroundColor.withValues(alpha: 0.3),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    size: 22,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (_isLocal) {
      return frame(const SizedBox.shrink(), showPlay: true);
    }

    return MediaDownloadGate(
      secureUrl: widget.videoUrl,
      isVideo: true,
      fileSizeBytes: widget.fileSizeBytes,
      durationSeconds: widget.durationSeconds,
      borderRadius: borderRadius,
      previewBuilder: (context) => frame(const SizedBox.shrink()),
      completedBuilder:
          (context, localPath) => GestureDetector(
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => FullScreenMediaView(
                          videoUrl: widget.videoUrl,
                          caption: widget.caption,
                        ),
                  ),
                ),
            child: frame(const SizedBox.shrink(), showPlay: true),
          ),
    );
  }
}
