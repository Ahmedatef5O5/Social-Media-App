import 'dart:convert';
import '../../features/auth/services/auth_recovery_coordinator.dart';
import '../supabase/supabase_provider.dart';

/// One place that answers "may session-bound code run right now?".
///
/// Three conditions are needed, not one:
///  * a password-recovery link creates a REAL Supabase session, so
///    `SupabaseProvider.isAuthenticated` is already `true` while the user is
///    still on the "Create New Password" screen;
///  * `SupabaseProvider.client` throws when Supabase failed to initialise;
///  * after a correct password Supabase issues an `aal1` session even when the
///    account has TOTP enabled. Such a session must not reach Home until the
///    second factor upgrades it to `aal2`.
class SessionGuard {
  SessionGuard._();

  /// A Supabase session exists (also true during password recovery / MFA).
  static bool get hasSession {
    try {
      return SupabaseProvider.isAuthenticated;
    } catch (_) {
      return false;
    }
  }

  /// Password/OAuth succeeded (aal1), the account has a verified TOTP factor,
  /// and this session has not passed it yet.
  ///
  /// Reads only data persisted with the session (the JWT `aal` claim and
  /// `user.factors`), so it is synchronous and works offline on a cold start.
  ///
  /// Fails OPEN on purpose: a parsing bug here must not lock every user out.
  /// The real enforcement is server side (`mfa_aal_satisfied()` + RLS).
  static bool get isMfaChallengePending {
    try {
      final session = SupabaseProvider.currentSession;
      if (session == null) return false;

      final enrolled = (session.user.factors ?? const []).any(
        // toString() tolerates both an enum (FactorStatus.verified) and a
        // plain string ('verified') across supabase_flutter versions.
        (f) => f.status.toString().endsWith('verified'),
      );
      return enrolled && _aalOf(session.accessToken) != 'aal2';
    } catch (_) {
      return false;
    }
  }

  /// A normal, fully signed-in session: chats, groups, sharing, home...
  static bool get isFullySignedIn =>
      hasSession &&
      !AuthRecoveryCoordinator.isRecoveryPending &&
      !isMfaChallengePending;

  static String _aalOf(String jwt) {
    final payload = base64Url.normalize(jwt.split('.')[1]);
    final map = jsonDecode(utf8.decode(base64Url.decode(payload))) as Map;
    return (map['aal'] as String?) ?? 'aal1';
  }
}
