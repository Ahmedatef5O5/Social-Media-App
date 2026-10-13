import '../../features/auth/services/auth_recovery_coordinator.dart';
import '../supabase/supabase_provider.dart';

/// One place that answers "may session-bound code run right now?".
///
/// Two conditions are needed, not one:
///  * a password-recovery link creates a REAL Supabase session, so
///    `SupabaseProvider.isAuthenticated` is already `true` while the user is
///    still on the "Create New Password" screen;
///  * `SupabaseProvider.client` throws when Supabase failed to initialise.
class SessionGuard {
  SessionGuard._();

  /// A Supabase session exists (also true during password recovery).
  static bool get hasSession {
    try {
      return SupabaseProvider.isAuthenticated;
    } catch (_) {
      return false;
    }
  }

  /// A normal, fully signed-in session: chats, groups, sharing, home...
  static bool get isFullySignedIn =>
      hasSession && !AuthRecoveryCoordinator.isRecoveryPending;
}
