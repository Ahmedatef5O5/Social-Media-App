import 'package:shared_preferences/shared_preferences.dart';

/// Client-side brute-force pause for the login challenge.
///
/// UX ONLY. A client can be reinstalled or scripted, so the real limits are
/// Supabase's MFA rate limit and `mfa_recovery_attempts` on the server. This
/// store exists so an honest user sees a countdown that survives app restarts.
///
/// Policy: 5 consecutive failures -> pause 30s, then 60s, 120s ... capped at
/// 15 minutes. A success resets everything.
class TwoFactorLockoutStore {
  static const int maxFailures = 5;
  static const Duration _base = Duration(seconds: 30);
  static const Duration _cap = Duration(minutes: 15);

  final DateTime Function() _now;

  TwoFactorLockoutStore({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  String _k(String userId, String f) => 'tf_lockout_${userId}_$f';

  /// Time left on the current pause, or null when not paused.
  Future<Duration?> remaining(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final until = prefs.getInt(_k(userId, 'until'));
    if (until == null) return null;
    final left = DateTime.fromMillisecondsSinceEpoch(until).difference(_now());
    return left > Duration.zero ? left : null;
  }

  /// Records a wrong code. Returns the pause that started, if any, so the UI
  /// can begin its countdown immediately.
  Future<Duration?> recordFailure(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final fails = (prefs.getInt(_k(userId, 'fails')) ?? 0) + 1;

    if (fails < maxFailures) {
      await prefs.setInt(_k(userId, 'fails'), fails);
      return null;
    }

    final round = prefs.getInt(_k(userId, 'round')) ?? 0;
    var pause = _base * (1 << round);
    if (pause > _cap) pause = _cap;

    await prefs.setInt(_k(userId, 'fails'), 0);
    await prefs.setInt(_k(userId, 'round'), round + 1);
    await prefs.setInt(
      _k(userId, 'until'),
      _now().add(pause).millisecondsSinceEpoch,
    );
    return pause;
  }

  Future<int> failures(String userId) async =>
      (await SharedPreferences.getInstance()).getInt(_k(userId, 'fails')) ?? 0;

  Future<void> reset(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    for (final f in const ['fails', 'round', 'until']) {
      await prefs.remove(_k(userId, f));
    }
  }
}
