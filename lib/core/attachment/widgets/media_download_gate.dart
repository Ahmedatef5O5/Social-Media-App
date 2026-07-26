import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cache/repository/media_cache_repository.dart';
import '../models/media_transfer_state.dart';
import 'media_state_overlay.dart';

enum _GatePhase { notDownloaded, downloading, completed, failed }

class MediaDownloadGate extends StatefulWidget {
  final String secureUrl;
  final bool isVideo;
  final int? fileSizeBytes;
  final int? durationSeconds;
  final BorderRadius borderRadius;
  final WidgetBuilder previewBuilder;
  final Widget Function(BuildContext context, String localFilePath)
  completedBuilder;

  const MediaDownloadGate({
    super.key,
    required this.secureUrl,
    required this.previewBuilder,
    required this.completedBuilder,
    this.isVideo = false,
    this.fileSizeBytes,
    this.durationSeconds,
    this.borderRadius = BorderRadius.zero,
  });

  @override
  State<MediaDownloadGate> createState() => _MediaDownloadGateState();
}

class _MediaDownloadGateState extends State<MediaDownloadGate> {
  _GatePhase _phase = _GatePhase.notDownloaded;
  double _progress = 0;
  String? _localPath;
  CancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    _checkExistingCache();
  }

  @override
  void didUpdateWidget(covariant MediaDownloadGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.secureUrl != widget.secureUrl) {
      _cancelToken?.cancel('url_changed');
      _phase = _GatePhase.notDownloaded;
      _localPath = null;
      _checkExistingCache();
    }
  }

  void _checkExistingCache() {
    final cached = context.read<MediaCacheRepository>().resolveLocalPathSync(
      widget.secureUrl,
    );
    if (cached != null && mounted) {
      setState(() {
        _phase = _GatePhase.completed;
        _localPath = cached;
      });
    }
  }

  Future<void> _startDownload() async {
    if (_phase == _GatePhase.downloading) return;
    final repo = context.read<MediaCacheRepository>();
    final cancelToken = CancelToken();
    _cancelToken = cancelToken;

    setState(() {
      _phase = _GatePhase.downloading;
      _progress = 0;
    });

    try {
      final path = await repo.resolveLocalPath(
        widget.secureUrl,
        cancelToken: cancelToken,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      if (!mounted) return;
      setState(() {
        if (path != null) {
          _phase = _GatePhase.completed;
          _localPath = path;
        } else {
          _phase = _GatePhase.failed;
        }
      });
    } catch (e) {
      if (!mounted) return;
      final wasCancelled = e is DioException && CancelToken.isCancel(e);
      setState(
        () =>
            _phase =
                wasCancelled ? _GatePhase.notDownloaded : _GatePhase.failed,
      );
    }
  }

  void _cancelDownload() {
    _cancelToken?.cancel('user_cancelled');
    setState(() => _phase = _GatePhase.notDownloaded);
  }

  MediaTransferState get _overlayState {
    switch (_phase) {
      case _GatePhase.notDownloaded:
        return const MediaTransferState.notDownloaded();
      case _GatePhase.downloading:
        return MediaTransferState.downloading(_progress);
      case _GatePhase.completed:
        return const MediaTransferState.completed();
      case _GatePhase.failed:
        return const MediaTransferState.failed(MediaTransferDirection.download);
    }
  }

  @override
  void dispose() {
    _cancelToken?.cancel('disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content =
        _phase == _GatePhase.completed && _localPath != null
            ? widget.completedBuilder(context, _localPath!)
            : widget.previewBuilder(context);

    return MediaStateOverlay(
      state: _overlayState,
      isVideo: widget.isVideo,
      fileSizeBytes: widget.fileSizeBytes,
      durationSeconds: widget.durationSeconds,
      borderRadius: widget.borderRadius,
      onDownloadTap: _startDownload,
      onCancelTap: _cancelDownload,
      onRetryTap: _startDownload,
      child: content,
    );
  }
}
