import 'package:livekit_client/livekit_client.dart';

class CallPipState {
  final Room? room;
  final bool isMinimized;
  final bool isVideo;
  final VideoTrack? previewTrack;

  const CallPipState({
    this.room,
    this.isMinimized = false,
    this.isVideo = false,
    this.previewTrack,
  });

  bool get hasActiveRoom => room != null;

  CallPipState copyWith({
    Room? room,
    bool? isMinimized,
    bool? isVideo,
    VideoTrack? previewTrack,
    bool clearPreviewTrack = false,
  }) {
    return CallPipState(
      room: room ?? this.room,
      isMinimized: isMinimized ?? this.isMinimized,
      isVideo: isVideo ?? this.isVideo,
      previewTrack:
          clearPreviewTrack ? null : (previewTrack ?? this.previewTrack),
    );
  }
}
