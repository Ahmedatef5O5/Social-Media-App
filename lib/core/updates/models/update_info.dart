import 'update_track.dart';

/// Snapshot of what the updater knows right now. Immutable.
class UpdateInfo {
  const UpdateInfo({
    required this.updaterAvailable,
    required this.track,
    this.currentPatch,
    this.lastCheckedAt,
  });

  /// `false` in debug / `flutter run` builds and in builds not created with
  /// `shorebird release`. Every update call is then a no-op.
  final bool updaterAvailable;
  final AppUpdateTrack track;

  /// Patch number the engine is running right now (`null` = base release).
  final int? currentPatch;
  final DateTime? lastCheckedAt;

  UpdateInfo copyWith({
    bool? updaterAvailable,
    AppUpdateTrack? track,
    int? currentPatch,
    bool clearCurrentPatch = false,
    DateTime? lastCheckedAt,
  }) {
    return UpdateInfo(
      updaterAvailable: updaterAvailable ?? this.updaterAvailable,
      track: track ?? this.track,
      currentPatch: clearCurrentPatch ? null : (currentPatch ?? this.currentPatch),
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is UpdateInfo &&
      other.updaterAvailable == updaterAvailable &&
      other.track == track &&
      other.currentPatch == currentPatch &&
      other.lastCheckedAt == lastCheckedAt;

  @override
  int get hashCode =>
      Object.hash(updaterAvailable, track, currentPatch, lastCheckedAt);

  @override
  String toString() =>
      'UpdateInfo(available: $updaterAvailable, track: ${track.wire}, patch: $currentPatch)';
}

/// Server-controlled behaviour (`get_update_policy()`); defaults apply when the
/// server cannot be reached, so an outage never disables updates.
class UpdatePolicy {
  const UpdatePolicy({
    this.telemetryEnabled = true,
    this.autoCheckEnabled = true,
    this.stagingTrackEnabled = false,
    this.blockDuringCalls = true,
    this.minCheckInterval = const Duration(minutes: 60),
  });

  final bool telemetryEnabled;
  final bool autoCheckEnabled;
  final bool stagingTrackEnabled;
  final bool blockDuringCalls;
  final Duration minCheckInterval;

  static const UpdatePolicy defaults = UpdatePolicy();

  factory UpdatePolicy.fromJson(Object? raw) {
    if (raw is! Map) return defaults;
    bool b(String k, bool d) => raw[k] is bool ? raw[k] as bool : d;
    final minutes = raw['min_check_interval_minutes'];
    return UpdatePolicy(
      telemetryEnabled: b('telemetry_enabled', true),
      autoCheckEnabled: b('auto_check_enabled', true),
      stagingTrackEnabled: b('staging_track_enabled', false),
      blockDuringCalls: b('block_during_calls', true),
      minCheckInterval: Duration(
        minutes: minutes is int && minutes >= 5 && minutes <= 1440 ? minutes : 60,
      ),
    );
  }
}
