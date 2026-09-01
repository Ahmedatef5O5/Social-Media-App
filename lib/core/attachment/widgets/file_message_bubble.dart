import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../cache/repository/media_cache_repository.dart';
import '../../helpers/bidi_text_helper.dart';
import '../../helpers/file_icon_helper.dart';
import '../../helpers/modern_progress_painter.dart';

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

    final currentBytes = progress * totalBytes;

    String formatBytes(double bytes) {
      if (bytes < 1024) return '${bytes.toStringAsFixed(0)} B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }

    return '${formatBytes(currentBytes)} / ${formatBytes(totalBytes.toDouble())}';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.primaryColor;
    final ext = _getFileExtension();
    final (fileIcon, iconAccent) = FileIconHelper.getIconAndColor(ext, primary);

    final Color fg =
        widget.isMe
            ? Colors.white
            : (isDark
                ? Colors.white
                : (iconAccent.computeLuminance() < 0.45
                    ? iconAccent
                    : theme.colorScheme.onSurface));

    final Color bg =
        widget.isMe
            ? Colors.white.withValues(alpha: 0.18)
            : (isDark
                ? iconAccent.withValues(alpha: 0.16)
                : iconAccent.withValues(alpha: 0.08));

    final Border border = Border.all(
      color:
          widget.isMe
              ? Colors.white.withValues(alpha: 0.28)
              : iconAccent.withValues(alpha: isDark ? 0.35 : 0.22),
      width: 1,
    );

    final bool isTransferring = widget.isUploading || _isDownloading;
    final double currentProgress =
        widget.isUploading ? (widget.uploadProgress ?? 0.0) : _downloadProgress;

    final sizeStr = _formatSize(widget.fileSizeBytes);
    final bool isDownloaded = _localPath != null || widget.isMe;
    final displayName =
        widget.fileName?.trim().isNotEmpty == true ? widget.fileName! : 'File';
    final textDirection = BidiTextHelper.detectDirection(displayName);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _handleTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: border,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Smooth Animated Container for the Icon / Download State
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeInOutCubic,
              switchOutCurve: Curves.easeInOutCubic,
              transitionBuilder:
                  (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
              child: Container(
                key: ValueKey<String>(
                  isTransferring
                      ? 'transferring'
                      : (isDownloaded ? 'downloaded' : 'needs_download'),
                ),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color:
                      isTransferring
                          ? Colors.transparent
                          : (isDownloaded
                              ? (widget.isMe ? Colors.white : Colors.white)
                              : iconAccent.withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow:
                      isTransferring || !isDownloaded
                          ? null
                          : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
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
                        : (isDownloaded
                            ? FaIcon(fileIcon, color: iconAccent, size: 24)
                            : Icon(
                              Icons.arrow_downward_rounded,
                              color: widget.isMe ? Colors.white : iconAccent,
                              size: 22,
                            )),
              ),
            ),
            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: textDirection,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 5),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color:
                              widget.isMe
                                  ? Colors.white.withValues(alpha: 0.25)
                                  : iconAccent.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          ext,
                          style: TextStyle(
                            color: widget.isMe ? Colors.white : iconAccent,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),

                      if (sizeStr.isNotEmpty)
                        Text(
                          sizeStr,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: fg.withValues(alpha: 0.82),
                            fontSize: 11,
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
            width: 26,
            height: 26,
            child: Stack(
              alignment: Alignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: clamped),
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  builder: (context, value, _) {
                    return CustomPaint(
                      size: const Size(26, 26),
                      painter: ModernProgressPainter(
                        progress: value,
                        backgroundColor: color.withValues(alpha: 0.25),
                        progressColor: color,
                      ),
                    );
                  },
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
