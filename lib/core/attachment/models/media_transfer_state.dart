import 'package:flutter/foundation.dart';

enum MediaTransferStage { completed, notDownloaded, inProgress, failed }

enum MediaTransferDirection { upload, download }

@immutable
class MediaTransferState {
  final MediaTransferStage stage;
  final MediaTransferDirection direction;
  final double progress;

  const MediaTransferState._({
    required this.stage,
    required this.direction,
    this.progress = 0.0,
  });

  const MediaTransferState.completed({
    MediaTransferDirection direction = MediaTransferDirection.download,
  }) : this._(stage: MediaTransferStage.completed, direction: direction);

  const MediaTransferState.notDownloaded()
    : this._(
        stage: MediaTransferStage.notDownloaded,
        direction: MediaTransferDirection.download,
      );

  const MediaTransferState.uploading(double progress)
    : this._(
        stage: MediaTransferStage.inProgress,
        direction: MediaTransferDirection.upload,
        progress: progress,
      );

  const MediaTransferState.downloading(double progress)
    : this._(
        stage: MediaTransferStage.inProgress,
        direction: MediaTransferDirection.download,
        progress: progress,
      );

  const MediaTransferState.failed(MediaTransferDirection direction)
    : this._(stage: MediaTransferStage.failed, direction: direction);

  bool get isUpload => direction == MediaTransferDirection.upload;

  @override
  bool operator ==(Object other) =>
      other is MediaTransferState &&
      other.stage == stage &&
      other.direction == direction &&
      other.progress == progress;

  @override
  int get hashCode => Object.hash(stage, direction, progress);
}
