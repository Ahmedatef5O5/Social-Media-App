import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../cache/repository/media_cache_repository.dart';
import '../../helpers/bidi_text_helper.dart';
import '../../helpers/file_icon_helper.dart';
import '../../helpers/formatted_date.dart';
import '../../supabase/supabase_provider.dart';
import '../../utilities/file_size_formatter.dart';
import '../models/shared_media_item.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

class DocumentFullScreenView extends StatefulWidget {
  final SharedMediaItem item;
  final bool isActive;

  const DocumentFullScreenView({
    super.key,
    required this.item,
    this.isActive = true,
  });

  @override
  State<DocumentFullScreenView> createState() => _DocumentFullScreenViewState();
}

class _DocumentFullScreenViewState extends State<DocumentFullScreenView> {
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
  void didUpdateWidget(covariant DocumentFullScreenView oldWidget) {
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
      setState(() => _localPath = cached);
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

  Future<void> _openFile() async {
    final url = widget.item.fileUrl;
    if (url != null && url.isNotEmpty) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    final size = MediaQuery.sizeOf(context);

    final rawName =
        widget.item.fileName ??
        (widget.item.text.isNotEmpty ? widget.item.text : context.l10n.file);
    final dotIndex = rawName.lastIndexOf('.');
    final baseName = dotIndex != -1 ? rawName.substring(0, dotIndex) : rawName;
    final extPart = dotIndex != -1 ? rawName.substring(dotIndex + 1) : '';
    final isArabic =
        BidiTextHelper.detectDirection(baseName) == TextDirection.rtl;
    final displayName =
        isArabic && extPart.isNotEmpty ? '$baseName .$extPart' : rawName;

    final ext =
        extPart.isNotEmpty
            ? extPart.toLowerCase()
            : (widget.item.fileUrl != null && widget.item.fileUrl!.contains('.')
                ? widget.item.fileUrl!
                    .substring(widget.item.fileUrl!.lastIndexOf('.') + 1)
                    .toLowerCase()
                : 'file');

    final (fileIcon, iconAccent) = FileIconHelper.getIconAndColor(ext, primary);
    final sizeStr = formatMediaFileSize(widget.item.fileSizeBytes);
    final isDownloaded = _localPath != null || _isMe;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isMe ? context.l10n.you : widget.item.senderName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          FormattedDate.getFormattedDate(
                            widget.item.createdAt.toString(),
                          ),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Center(
              child: Container(
                width: size.width * 0.85,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 26,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: iconAccent.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child:
                          _isDownloading
                              ? SizedBox(
                                width: 44,
                                height: 44,
                                child: CircularProgressIndicator(
                                  value:
                                      _downloadProgress > 0
                                          ? _downloadProgress
                                          : null,
                                  strokeWidth: 3.5,
                                  valueColor: AlwaysStoppedAnimation(
                                    iconAccent,
                                  ),
                                ),
                              )
                              : isDownloaded
                              ? FaIcon(fileIcon, color: iconAccent, size: 42)
                              : Icon(
                                Icons.arrow_downward_rounded,
                                color: iconAccent,
                                size: 42,
                              ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                      textDirection:
                          isArabic ? TextDirection.rtl : TextDirection.ltr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: iconAccent.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            ext.toUpperCase(),
                            style: TextStyle(
                              color: iconAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        if (sizeStr.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            sizeStr,
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: iconAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        onPressed:
                            _isDownloading
                                ? null
                                : (isDownloaded ? _openFile : _startDownload),
                        icon: Icon(
                          isDownloaded
                              ? Icons.open_in_new_rounded
                              : Icons.download_rounded,
                          size: 20,
                        ),
                        label: Text(
                          isDownloaded
                              ? context.l10n.open
                              : context.l10n.download,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
