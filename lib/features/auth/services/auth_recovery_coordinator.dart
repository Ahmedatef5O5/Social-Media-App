import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/supabase/supabase_provider.dart';

/// Tracks "the user arrived through a password-recovery link and has not set a
/// new password yet".

class AuthRecoveryCoordinator {
  AuthRecoveryCoordinator._();

  static const String _kPendingTsKey = 'auth_recovery_pending_ts';
  static const Duration _ttl = Duration(minutes: 60);

  static bool _isRecoveryPending = false;
  static bool get isRecoveryPending => _isRecoveryPending;

  /// Call once during bootstrap, after Supabase is initialised.
  static Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt(_kPendingTsKey);
    if (ts == null) return;

    final ageMs = DateTime.now().millisecondsSinceEpoch - ts;
    final hasSession = SupabaseProvider.currentSession != null;
    if (ageMs < _ttl.inMilliseconds && hasSession) {
      _isRecoveryPending = true;
    } else {
      await prefs.remove(_kPendingTsKey);
    }
  }

  static void markRecoveryPending() {
    _isRecoveryPending = true;
    unawaited(_persist());
  }

  static void consumeRecovery() {
    _isRecoveryPending = false;
    unawaited(_clearPersisted());
  }

  /// The user left the reset screen without choosing a password: the recovery
  /// session must not stay alive as a normal logged-in session.
  static Future<void> abandon() async {
    consumeRecovery();
    try {
      await SupabaseProvider.auth.signOut();
    } catch (_) {
      // Best effort: the auth listener / splash will cope with a stale session.
    }
  }

  static Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kPendingTsKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  static Future<void> _clearPersisted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kPendingTsKey);
    } catch (_) {}
  }
}
