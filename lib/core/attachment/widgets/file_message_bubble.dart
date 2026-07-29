import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  String _formatSize(int? bytes) {
    if (bytes == null) return '';
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
    final fg = widget.isMe ? Colors.white : primary;
    final bg =
        widget.isMe
            ? Colors.white.withValues(alpha: 0.16)
            : primary.withValues(alpha: 0.1);

    final bool isTransferring = widget.isUploading || _isDownloading;
    final double currentProgress =
        widget.isUploading ? (widget.uploadProgress ?? 0.0) : _downloadProgress;

    final bool needsDownload =
        !widget.isUploading && _localPath == null && !_isDownloading;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _handleTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 58,
              child:
                  isTransferring
                      ? _TransferProgressIcon(
                        progress: currentProgress,
                        color: fg,
                        totalBytes: widget.fileSizeBytes,
                        formatTransfer: _formatTransfer,
                        onCancel:
                            widget.isUploading
                                ? widget.onCancelTap
                                : _cancelDownload,
                      )
                      : Icon(
                        needsDownload
                            ? Icons.download_rounded
                            : Icons.insert_drive_file_rounded,
                        color: fg,
                        size: 28,
                      ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.fileName ?? 'File',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _formatSize(widget.fileSizeBytes),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: fg.withValues(alpha: 0.7),
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
            width: 24,
            height: 24,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: clamped > 0 ? clamped : null,
                  strokeWidth: 2.2,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.2),
                ),

                Icon(Icons.close_rounded, size: 12.5, color: color),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            formatTransfer(clamped, totalBytes),
            style: TextStyle(
              color: color,
              fontSize: 7.5,
              fontWeight: FontWeight.w700,
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
