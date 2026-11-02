/// Release track a build listens to.
///
/// Named `AppUpdateTrack` (not `UpdateTrack`) on purpose: `package:shorebird_code_push`
/// exports its own `UpdateTrack`, and importing both unqualified would clash.
enum AppUpdateTrack {
  staging,
  stable;

  /// Value sent to Supabase / used in `--track=`.
  String get wire => name;

  static AppUpdateTrack parse(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'staging':
        return AppUpdateTrack.staging;
      default:
        // Anything unknown (including null) maps to the safe, public track.
        return AppUpdateTrack.stable;
    }
  }
}
