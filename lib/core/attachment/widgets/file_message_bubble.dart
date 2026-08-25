import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../cache/repository/media_cache_repository.dart';

class FileMessageBubble extends StatefulWidget {
  final String fileUrl;
  final String? fileName;
  final int? fileSizeBytes;
  final bool isMe;
  final bool isUploading;
  final double? uploadProgress;
  final VoidCallback? onCancelTap;

  const FileMessageBubble({
    super.key,
    required this.fileUrl,
    this.fileName,
    this.fileSizeBytes,
    this.isMe = false,
    this.isUploading = false,
    this.uploadProgress,
    this.onCancelTap,
  });

  @override
  State<FileMessageBubble> createState() => _FileMessageBubbleState();
}

class _FileMessageBubbleState extends State<FileMessageBubble> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _localPath;
  CancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    _checkExistingCache();
  }

  @override
  void didUpdateWidget(covariant FileMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fileUrl != widget.fileUrl) {
      _cancelToken?.cancel();
      _isDownloading = false;
      _localPath = null;
      _checkExistingCache();
    }
  }

  void _checkExistingCache() {
    if (widget.isUploading || !widget.fileUrl.startsWith('http')) {
      _localPath = widget.fileUrl;
      return;
    }

    final repo = context.read<MediaCacheRepository>();
    final cached = repo.resolveLocalPathSync(widget.fileUrl);
    if (cached != null) {
      setState(() => _localPath = cached);
    }
  }

  Future<void> _startDownload() async {
    if (_isDownloading) return;
    final repo = context.read<MediaCacheRepository>();
    final cancelToken = CancelToken();
    _cancelToken = cancelToken;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final path = await repo.resolveLocalPath(
        widget.fileUrl,
        cancelToken: cancelToken,
        onProgress: (p) {
          if (mounted) setState(() => _downloadProgress = p);
        },
      );
      if (mounted) {
        setState(() {
          if (path != null) _localPath = path;
          _isDownloading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  void _cancelDownload() {
    _cancelToken?.cancel('user_cancelled');
    setState(() {
      _isDownloading = false;
      _downloadProgress = 0.0;
    });
  }

  String _getFileExtension() {
    final name = widget.fileName ?? widget.fileUrl;
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
      case 'md':
      case 'rtf':
        return (FontAwesomeIcons.solidFileLines, const Color(0xFF555555));
      case 'json':
      case 'dart':
      case 'py':
      case 'js':
      case 'html':
      case 'xml':
        return (FontAwesomeIcons.solidFileCode, const Color(0xFF00B4D8));
      case 'zip':
      case 'rar':
      case '7z':
        return (FontAwesomeIcons.solidFileZipper, Colors.amber.shade700);
      case 'mp3':
      case 'wav':
      case 'm4a':
        return (FontAwesomeIcons.solidFileAudio, Colors.purpleAccent);
      case 'mp4':
      case 'avi':
      case 'mkv':
        return (FontAwesomeIcons.solidFileVideo, Colors.redAccent);
      case 'png':
      case 'jpg':
      case 'jpeg':
        return (FontAwesomeIcons.solidFileImage, const Color(0xFF2E8B57));
      default:
        return (FontAwesomeIcons.solidFile, defaultColor);
    }
  }

  String _formatSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatTransfer(double progress, int? totalBytes) {
    if (totalBytes == null || totalBytes == 0) {
      final percent = (progress.clamp(0.0, 1.0) * 100).round();
      return '$percent%';
    }
    final currentBytes = (progress * totalBytes).round();

    if (totalBytes < 1024 * 1024) {
      final curKB = (currentBytes / 1024).toStringAsFixed(1);
      final totKB = (totalBytes / 1024).toStringAsFixed(1);
      return '$curKB / $totKB KB';
    } else {
      final curMB = (currentBytes / (1024 * 1024)).toStringAsFixed(1);
      final totMB = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
      return '$curMB / $totMB MB';
    }
  }

  void _handleTap() {
    if (widget.isUploading) {
      widget.onCancelTap?.call();
      return;
    }

    if (_isDownloading) {
      _cancelDownload();
      return;
    }

    if (_localPath != null || widget.isMe) {
      launchUrl(
        Uri.parse(widget.fileUrl),
        mode: LaunchMode.externalApplication,
      );
    } else {
      _startDownload();
    }
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final ext = _getFileExtension();
    final (fileIcon, iconAccent) = _getFileIconAndColor(ext, primary);

    final fg = widget.isMe ? Colors.white : primary;
    final bg =
        widget.isMe
            ? Colors.white.withValues(alpha: 0.16)
            : primary.withValues(alpha: 0.08);

    final bool isTransferring = widget.isUploading || _isDownloading;
    final double currentProgress =
        widget.isUploading ? (widget.uploadProgress ?? 0.0) : _downloadProgress;

    final bool needsDownload =
        !widget.isUploading && _localPath == null && !_isDownloading;

    final sizeStr = _formatSize(widget.fileSizeBytes);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: _handleTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color:
                    isTransferring
                        ? Colors.transparent
                        : (widget.isMe
                            ? Colors.white
                            : iconAccent.withValues(alpha: 0.12)),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child:
                  isTransferring
                      ? _TransferProgressIcon(
                        progress: currentProgress,
                        color: widget.isMe ? Colors.white : iconAccent,
                        totalBytes: widget.fileSizeBytes,
                        formatTransfer: _formatTransfer,
                        onCancel:
                            widget.isUploading
                                ? widget.onCancelTap
                                : _cancelDownload,
                      )
                      : FaIcon(
                        needsDownload ? FontAwesomeIcons.download : fileIcon,
                        color: iconAccent,
                        size: 26,
                      ),
            ),
            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.fileName?.trim().isNotEmpty == true
                        ? widget.fileName!
                        : 'File',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 5),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: (widget.isMe ? Colors.white : iconAccent)
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          ext,
                          style: TextStyle(
                            color: widget.isMe ? Colors.white : iconAccent,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),

                      if (sizeStr.isNotEmpty)
                        Text(
                          sizeStr,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: fg.withValues(alpha: 0.8),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
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

class _TransferProgressIcon extends StatelessWidget {
  final double progress;
  final Color color;
  final int? totalBytes;
  final String Function(double, int?) formatTransfer;
  final VoidCallback? onCancel;

  const _TransferProgressIcon({
    required this.progress,
    required this.color,
    required this.totalBytes,
    required this.formatTransfer,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onCancel,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: 22,
            height: 22,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: clamped > 0 ? clamped : null,
                  strokeWidth: 2.5,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.2),
                ),
                Icon(Icons.close_rounded, size: 12, color: color),
              ],
            ),
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            formatTransfer(clamped, totalBytes),
            style: TextStyle(
              color: color,
              fontSize: 7.5,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}
