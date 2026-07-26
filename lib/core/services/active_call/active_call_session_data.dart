/// Immutable display-data snapshot for whichever call (1:1 or group) is
/// currently connected in the app.
///
/// This class intentionally holds **presentation data only** (title,
/// avatar, start time, etc.). It is NOT the source of truth for whether the
/// call is minimized right now — that responsibility stays with Zego's own
/// `ZegoUIKitPrebuiltCallController().minimize.isMinimizingNotifier`, so we
/// never risk the two states drifting out of sync.
class ActiveCallSessionData {
  /// Whether this session represents a group call (`true`) or a 1:1 call
  /// (`false`).
  final bool isGroup;

  /// The underlying call id used by both our Supabase signaling layer and
  /// the Zego room.
  final String callId;

  /// Display name shown in the header — the other participant's name for
  /// 1:1 calls, or the group's name for group calls.
  final String title;

  /// Avatar/thumbnail to render in the header. May be null/empty.
  final String? avatarUrl;

  /// Whether the call was started as a video call (used only for minor
  /// cosmetic decisions in the header, e.g. icon choice).
  final bool isVideo;

  /// The real connection time, used to keep the duration timer continuous
  /// between the full-screen call view and the minimized header.
  final DateTime startedAt;

  const ActiveCallSessionData({
    required this.isGroup,
    required this.callId,
    required this.title,
    required this.isVideo,
    required this.startedAt,
    this.avatarUrl,
  });

  ActiveCallSessionData copyWith({
    bool? isGroup,
    String? callId,
    String? title,
    String? avatarUrl,
    bool? isVideo,
    DateTime? startedAt,
  }) {
    return ActiveCallSessionData(
      isGroup: isGroup ?? this.isGroup,
      callId: callId ?? this.callId,
      title: title ?? this.title,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isVideo: isVideo ?? this.isVideo,
      startedAt: startedAt ?? this.startedAt,
    );
  }
}
