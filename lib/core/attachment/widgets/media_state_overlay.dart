import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:social_media_app/core/attachment/widgets/transfer_ring.dart';
import '../../helpers/media_duration_badge.dart';
import '../../utilities/file_size_formatter.dart';
import '../models/media_transfer_state.dart';

class MediaStateOverlay extends StatelessWidget {
  final Widget child;
  final MediaTransferState state;
  final BorderRadius borderRadius;
  final bool isVideo;
  final int? fileSizeBytes;
  final int? durationSeconds;
  final VoidCallback? onDownloadTap;
  final VoidCallback? onCancelTap;
  final VoidCallback? onRetryTap;
  final double ringSize;

  const MediaStateOverlay({
    super.key,
    required this.child,
    required this.state,
    this.borderRadius = BorderRadius.zero,
    this.isVideo = false,
    this.fileSizeBytes,
    this.durationSeconds,
    this.onDownloadTap,
    this.onCancelTap,
    this.onRetryTap,
    this.ringSize = 30,
  });

  bool get _needsBlur {
    switch (state.stage) {
      case MediaTransferStage.notDownloaded:
        return true;
      case MediaTransferStage.inProgress:
      case MediaTransferStage.failed:
        return !state.isUpload;
      case MediaTransferStage.completed:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          child,
          if (_needsBlur)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(color: Colors.black.withValues(alpha: 0.18)),
              ),
            ),
          Positioned.fill(
            child: IgnorePointer(
              ignoring: state.stage == MediaTransferStage.completed,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _buildChrome(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChrome(BuildContext context) {
    switch (state.stage) {
      case MediaTransferStage.completed:
        return const SizedBox.shrink(key: ValueKey('completed'));

      case MediaTransferStage.notDownloaded:
        return _TopLeftBadge(
          key: const ValueKey('pending'),
          isVideo: isVideo,
          durationSeconds: durationSeconds,
          leading: _StaticIconButton(
            size: ringSize,
            icon: Icons.arrow_downward_rounded,
            onTap: onDownloadTap,
          ),
          caption: formatMediaFileSize(fileSizeBytes),
        );

      case MediaTransferStage.inProgress:
        return _TopLeftBadge(
          key: ValueKey('progress-${state.direction}'),
          isVideo: isVideo,
          durationSeconds: durationSeconds,
          leading: TransferRing(
            size: ringSize,
            progress: state.progress,
            icon: Icons.close_rounded,
            onTap: onCancelTap,
          ),
          caption:
              state.isUpload
                  ? formatMediaFileSize(fileSizeBytes)
                  : formatMediaFileSizeRatio(
                    ((fileSizeBytes ?? 0) * state.progress).round(),
                    fileSizeBytes,
                  ),
        );

      case MediaTransferStage.failed:
        return _TopLeftBadge(
          key: ValueKey('failed-${state.direction}'),
          isVideo: isVideo,
          durationSeconds: durationSeconds,
          leading: _StaticIconButton(
            size: ringSize,
            icon: Icons.refresh_rounded,
            onTap: onRetryTap,
            tint: Colors.redAccent,
          ),
          caption: null,
        );
    }
  }
}

class _TopLeftBadge extends StatelessWidget {
  final Widget leading;
  final String? caption;
  final bool isVideo;
  final int? durationSeconds;

  const _TopLeftBadge({
    super.key,
    required this.leading,
    required this.caption,
    required this.isVideo,
    required this.durationSeconds,
  });

  @override
  Widget build(BuildContext context) {
    const inset = 8.0;
    return Stack(
      children: [
        Positioned(
          top: inset,
          left: inset,
          child: GlassPillBadge(leading: leading, caption: caption),
        ),
        if (isVideo && durationSeconds != null)
          Positioned(
            top: inset,
            right: inset,
            child: MediaDurationBadge(seconds: durationSeconds),
          ),
      ],
    );
  }
}

class _StaticIconButton extends StatelessWidget {
  final double size;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? tint;

  const _StaticIconButton({
    required this.size,
    required this.icon,
    this.onTap,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              tint != null ? tint!.withValues(alpha: 0.85) : Colors.transparent,
        ),
        child: Icon(icon, size: size * 0.55, color: Colors.white),
      ),
    );
  }
}
