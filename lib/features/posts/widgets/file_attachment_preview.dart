import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/cache/repository/media_cache_repository.dart';
import '../../../core/helpers/bidi_text_helper.dart';
import '../../../core/helpers/modern_progress_painter.dart';

class FileAttachmentPreview extends StatefulWidget {
  final String url;
  final String? fileName;
  final int? fileSizeBytes;
  final bool isAuthor;

  const FileAttachmentPreview({
    super.key,
    required this.url,
    this.fileName,
    this.fileSizeBytes,
    this.isAuthor = false,
  });

  @override
  State<FileAttachmentPreview> createState() => _FileAttachmentPreviewState();
}

class _FileAttachmentPreviewState extends State<FileAttachmentPreview>
    with SingleTickerProviderStateMixin {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _localPath;
  CancelToken? _cancelToken;
  int? _resolvedSizeBytes;
  bool _showCheckmark = false;

  String get _cleanUrl {
    var u = widget.url;
    if (u.contains('/raw/upload/')) {
      u = u
          .replaceAllMapped(RegExp(r'/raw/upload/([^/]+)/(v\d+/)'), (match) {
            final transform = match.group(1)!;
            final version = match.group(2)!;
            if (transform.startsWith('c_')) return '/raw/upload/$version';
            return match.group(0)!;
          })
          .replaceAll(RegExp(r'/raw/upload/c_[^/]+/'), '/raw/upload/');
    }
    return u;
  }

  @override
  void initState() {
    super.initState();
    _resolvedSizeBytes = widget.fileSizeBytes;
    _checkExistingCache();
    if (_resolvedSizeBytes == null) {
      _fetchRemoteFileSize();
    }
  }

  Future<void> _fetchRemoteFileSize() async {
    try {
      if (!widget.url.startsWith('http')) return;
      final response = await Dio().head(_cleanUrl);
      final lengthStr = response.headers.value(HttpHeaders.contentLengthHeader);
      if (lengthStr != null && mounted) {
        setState(() {
          _resolvedSizeBytes = int.tryParse(lengthStr);
        });
      }
    } catch (e) {
      debugPrint('[FileAttachmentPreview] failed to resolve file size: $e');
    }
  }

  @override
  void didUpdateWidget(covariant FileAttachmentPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _cancelToken?.cancel();
      _isDownloading = false;
      _localPath = null;
      _resolvedSizeBytes = widget.fileSizeBytes;
      _showCheckmark = false;
      _checkExistingCache();
      if (_resolvedSizeBytes == null) {
        _fetchRemoteFileSize();
      }
    }
  }

  void _checkExistingCache() {
    if (!widget.url.startsWith('http')) {
      _localPath = widget.url;
      return;
    }
    final repo = context.read<MediaCacheRepository>();
    final cached = repo.resolveLocalPathSync(_cleanUrl);
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
      _showCheckmark = false;
    });

    try {
      final path = await repo.resolveLocalPath(
        _cleanUrl,
        cancelToken: cancelToken,
        onProgress: (p) {
          if (mounted) setState(() => _downloadProgress = p);
        },
      );
      if (mounted) {
        setState(() {
          if (path != null) {
            _localPath = path;
            _showCheckmark = true;
          }
          _isDownloading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  void _cancelDownload() {
    _cancelToken?.cancel('user_cancelled');
    setState(() {
      _isDownloading = false;
      _downloadProgress = 0.0;
    });
  }

  void _handleTap() {
    if (_isDownloading) {
      _cancelDownload();
      return;
    }
    if (_localPath != null || widget.isAuthor) {
      launchUrl(Uri.parse(_cleanUrl), mode: LaunchMode.externalApplication);
    } else {
      _startDownload();
    }
  }

  String _getFileName() {
    if (widget.fileName != null && widget.fileName!.isNotEmpty) {
      return widget.fileName!;
    }
    return _cleanUrl.split('/').last.split('?').first;
  }

  String _getFileExtension(String fileName) {
    if (fileName.contains('.')) {
      return fileName.substring(fileName.lastIndexOf('.') + 1).toUpperCase();
    }
    return 'FILE';
  }

  (IconData, Color) _getFileIconAndColor(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return (Icons.picture_as_pdf_rounded, const Color(0xFFE5252A));
      case 'doc':
      case 'docx':
        return (Icons.description_rounded, const Color(0xFF185ABD));
      case 'xls':
      case 'xlsx':
      case 'csv':
        return (Icons.table_chart_rounded, const Color(0xFF217346));
      case 'ppt':
      case 'pptx':
        return (Icons.slideshow_rounded, const Color(0xFFD24726));
      case 'txt':
      case 'rtf':
      case 'md':
        return (Icons.article_rounded, const Color(0xFF2E7D52));
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
        return (Icons.inventory_2_rounded, const Color(0xFFF59E0B));
      case 'mp3':
      case 'wav':
      case 'm4a':
      case 'ogg':
        return (Icons.audio_file_rounded, const Color(0xFF9333EA));
      case 'mp4':
      case 'avi':
      case 'mkv':
        return (Icons.video_file_rounded, const Color(0xFFE11D48));
      case 'json':
      case 'dart':
      case 'js':
      case 'ts':
      case 'html':
      case 'css':
        return (Icons.code_rounded, const Color(0xFF00B4D8));
      default:
        return (Icons.insert_drive_file_rounded, Colors.blueGrey);
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

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fileName = _getFileName();
    final ext = _getFileExtension(fileName);
    final (fileIcon, fileColor) = _getFileIconAndColor(ext);
    final textDirection = BidiTextHelper.detectDirection(fileName);
    final sizeStr = _formatSize(_resolvedSizeBytes);
    final bool isDownloaded = _localPath != null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color:
            isDark
                ? fileColor.withValues(alpha: 0.12)
                : fileColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: fileColor.withValues(alpha: isDark ? 0.28 : 0.18),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _handleTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icon Container
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(fileIcon, color: fileColor, size: 28),
                ),
              ),
              const Gap(14),

              // File Info
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: textDirection,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                    const Gap(5),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: fileColor.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            ext,
                            style: TextStyle(
                              color: fileColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 9.5,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        if (sizeStr.isNotEmpty) ...[
                          const Gap(8),
                          Text(
                            sizeStr,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.7),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Gap(8),

              // Modern Action Button
              _buildModernAction(fileColor, isDownloaded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernAction(Color fileColor, bool isDownloaded) {
    if (widget.isAuthor) {
      return const SizedBox.shrink(); // Author doesn't need icon
    }

    if (_isDownloading) {
      final clamped = _downloadProgress.clamp(0.0, 1.0);
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _cancelDownload,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 32,
              height: 32,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: clamped),
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    builder: (context, value, _) {
                      return CustomPaint(
                        size: const Size(32, 32),
                        painter: ModernProgressPainter(
                          progress: value,
                          backgroundColor: fileColor.withValues(alpha: 0.22),
                          progressColor: fileColor,
                        ),
                      );
                    },
                  ),
                  Icon(Icons.close_rounded, size: 14, color: fileColor),
                ],
              ),
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _formatTransfer(clamped, _resolvedSizeBytes),
              style: TextStyle(
                color: fileColor,
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    if (isDownloaded || _showCheckmark) {
      return AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green.withValues(alpha: 0.15),
          ),
          child: const Center(
            child: Icon(Icons.check_rounded, size: 18, color: Colors.green),
          ),
        ),
      );
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(shape: BoxShape.circle, color: fileColor),
      child: const Center(
        child: Icon(
          Icons.arrow_downward_rounded,
          size: 18,
          color: Colors.white,
        ),
      ),
    );
  }
}
