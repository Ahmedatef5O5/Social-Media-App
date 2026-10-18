import 'dart:io';

enum MediaEditorPreset {
  free,
  story,
  post,
  chat,
  comment,
  aiChat,
  feedback,

  /// 1:1 with a circular guide (profile picture).
  avatar,

  /// Wide banner (profile cover photo).
  cover,
}

/// Result of a successful video trim.
class TrimmedVideo {
  const TrimmedVideo({required this.file, required this.duration});

  final File file;
  final Duration duration;

  int get durationSeconds => duration.inSeconds;
}

/// Limits used by the trim UI. Kept here so every surface shares them.
class MediaEditorLimits {
  MediaEditorLimits._();

  /// Longest video a story may contain. The trim bar will not let the user
  /// select a longer window.
  static const Duration storyMaxVideoDuration = Duration(seconds: 60);

  /// Shortest clip the trim bar allows.
  static const Duration minTrimDuration = Duration(seconds: 1);
}
