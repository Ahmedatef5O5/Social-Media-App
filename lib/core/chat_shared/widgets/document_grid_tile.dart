import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../cache/repository/media_cache_repository.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../helpers/bidi_text_helper.dart';
import '../../helpers/file_icon_helper.dart';
import '../../helpers/modern_progress_painter.dart';
import '../../supabase/supabase_provider.dart';
import '../../utilities/file_size_formatter.dart';
import '../models/shared_media_item.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import '../../toast/app_toast.dart';

class DocumentGridTile extends StatefulWidget {
  final SharedMediaItem item;
  final VoidCallback? onTap;

  const DocumentGridTile({super.key, required this.item, this.onTap});

  static String extractExtension(String name, String? url) {
    final target = name.contains('.') ? name : (url ?? '');
    if (target.contains('.')) {
      return target.substring(target.lastIndexOf('.') + 1).toLowerCase();
    }
    return 'file';
  }

  static Future<void> openLocalFile(
    BuildContext context,
    String pathOrUrl,
  ) async {
    if (pathOrUrl.startsWith('http')) {
      final uri = Uri.parse(pathOrUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else {
      try {
        final result = await OpenFilex.open(pathOrUrl);
        if (result.type != ResultType.done && context.mounted) {
          final uri = Uri.file(pathOrUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            if (!context.mounted) return;
            AppToast.error(context.l10n.couldntOpenThatFile);
          }
        }
      } catch (_) {
        if (context.mounted) {
          AppToast.error(context.l10n.couldntOpenThatFile);
        }
      }
    }
  }

  @override
  State<DocumentGridTile> createState() => _DocumentGridTileState();
}

class _DocumentGridTileState extends State<DocumentGridTile> {
  String? _localPath;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  CancelToken? _cancelToken;

  bool get _isMe => widget.item.senderId == SupabaseProvider.id;

  @override
  void initState() {
    super.initState();
    _checkExistingCache();
  }

  @override
  void didUpdateWidget(covariant DocumentGridTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.fileUrl != widget.item.fileUrl) {
      _cancelToken?.cancel();
      _isDownloading = false;
      _localPath = null;
      _checkExistingCache();
    }
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  void _checkExistingCache() {
    final url = widget.item.fileUrl;
    if (url == null || url.isEmpty) return;

    if (_isMe || !url.startsWith('http')) {
      _localPath = url;
      return;
    }

    final repo = context.read<MediaCacheRepository>();
    final cached = repo.resolveLocalPathSync(url);
    if (cached != null) {
      _localPath = cached;
    }
  }

  Future<void> _startDownload() async {
    final url = widget.item.fileUrl;
    if (url == null || url.isEmpty || _isDownloading) return;

    final repo = context.read<MediaCacheRepository>();
    final cancelToken = CancelToken();
    _cancelToken = cancelToken;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final path = await repo.resolveLocalPath(
        url,
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
    if (mounted) {
      setState(() {
        _isDownloading = false;
        _downloadProgress = 0.0;
      });
    }
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
    if (widget.onTap != null) {
      widget.onTap!();
      return;
    }

    if (_isDownloading) {
      _cancelDownload();
      return;
    }

    final isDownloaded = _localPath != null || _isMe;
    if (isDownloaded) {
      DocumentGridTile.openLocalFile(
        context,
        _localPath ?? widget.item.fileUrl!,
      );
    } else {
      _startDownload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.primaryColor;

    final fileName =
        widget.item.fileName ??
        (widget.item.text.isNotEmpty ? widget.item.text : 'Document');
    final ext = DocumentGridTile.extractExtension(
      fileName,
      widget.item.fileUrl,
    );
    final (fileIcon, iconAccent) = FileIconHelper.getIconAndColor(ext, primary);

    final dotIndex = fileName.lastIndexOf('.');
    final baseName =
        dotIndex != -1 ? fileName.substring(0, dotIndex) : fileName;
    final extPart = dotIndex != -1 ? fileName.substring(dotIndex + 1) : '';
    final isArabic =
        BidiTextHelper.detectDirection(baseName) == TextDirection.rtl;
    final displayName =
        isArabic && extPart.isNotEmpty ? '$baseName .$extPart' : fileName;

    final sizeStr = formatMediaFileSize(widget.item.fileSizeBytes);
    final isDownloaded = _localPath != null || _isMe;
    final clamped = _downloadProgress.clamp(0.0, 1.0);

    return InkWell(
      onTap: _handleTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color:
              isDark
                  ? iconAccent.withValues(alpha: 0.14)
                  : iconAccent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: iconAccent.withValues(alpha: isDark ? 0.35 : 0.22),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _isDownloading ? _cancelDownload : null,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color:
                      _isDownloading
                          ? Colors.transparent
                          : (isDownloaded
                              ? (isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.white)
                              : iconAccent.withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow:
                      _isDownloading
                          ? null
                          : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                ),
                alignment: Alignment.center,
                child:
                    _isDownloading
                        ? SizedBox(
                          width: 34,
                          height: 34,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: clamped),
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOut,
                                builder: (context, value, _) {
                                  return CustomPaint(
                                    size: const Size(34, 34),
                                    painter: ModernProgressPainter(
                                      progress: value,
                                      backgroundColor: iconAccent.withValues(
                                        alpha: 0.22,
                                      ),
                                      progressColor: iconAccent,
                                    ),
                                  );
                                },
                              ),
                              Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: iconAccent,
                              ),
                            ],
                          ),
                        )
                        : (isDownloaded
                            ? FaIcon(fileIcon, color: iconAccent, size: 20)
                            : Icon(
                              Icons.arrow_downward_rounded,
                              color: iconAccent,
                              size: 20,
                            )),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: isArabic ? TextAlign.right : TextAlign.left,
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color:
                    isDark
                        ? Colors.white
                        : (iconAccent.computeLuminance() < 0.45
                            ? iconAccent
                            : theme.colorScheme.onSurface),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_isDownloading) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: iconAccent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      ext.toUpperCase(),
                      style: TextStyle(
                        color: iconAccent,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (sizeStr.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(
                      sizeStr,
                      textDirection: TextDirection.ltr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.75,
                        ),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ] else
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _formatTransfer(clamped, widget.item.fileSizeBytes),
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          color: iconAccent,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
