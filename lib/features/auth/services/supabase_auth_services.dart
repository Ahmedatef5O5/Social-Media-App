import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:social_media_app/features/auth/data/repository/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_pkg;
import '../../../core/deep_link/services/incoming_link_classifier.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/utilities/supabase_constants.dart';
import '../../../core/secrets/app_secrets.dart';
import '../data/models/account_auth_info.dart';
import '../data/models/user_data.dart';

/// Thrown when the re-authentication check rejects the typed current password.
class WrongCurrentPasswordException implements Exception {
  const WrongCurrentPasswordException();

  @override
  String toString() => 'WrongCurrentPasswordException';
}

class SupabaseAuthServices implements AuthRepository {
  final _supabase = SupabaseProvider.client;

  Stream<AuthState> get authStateStream => _supabase.auth.onAuthStateChange;

  supabase_pkg.User? get currentUser => _supabase.auth.currentUser;

  supabase_pkg.Session? get currentSession => _supabase.auth.currentSession;

  Future<AuthResponse> refreshSession() => _supabase.auth.refreshSession();

  Future<void> ensureUserExistsInDb(supabase_pkg.User user) async {
    try {
      final existingUser =
          await _supabase
              .from(SupabaseConstants.users)
              .select()
              .eq(UserColumns.id, user.id)
              .maybeSingle();

      if (existingUser == null) {
        final String userName =
            user.userMetadata?[UserColumns.name] ??
            user.userMetadata?['full_name'] ??
            user.userMetadata?['display_name'] ??
            'Social User';

        await setUserData(userName, user.email ?? '', user.id);
      }
    } catch (e) {
      debugPrint('Error ensuring user exists: $e');
      rethrow;
    }
  }

  @override
  Future<void> signInWithEmail(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) throw Exception('User not found');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> signUpWithEmail(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
      );
      if (response.user == null) throw Exception('User not found');
      await setUserData(name, email, response.user!.id);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AuthResponse> signInWithGoogle() async {
    try {
      const webClientId =
          '548020841452-cvtj4vs047g5acgtsmga02990tfagvg4.apps.googleusercontent.com';
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: webClientId,
      );
      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        throw 'Sign in aborted by user';
        // return ;
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw 'No ID Token found';
      }

      final AuthResponse response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      return response;
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> signInWithFacebook() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: 'socialapp://login-callback',
        // authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('Facebook Sign-In Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> signInWithMicrosoft() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.azure,
        redirectTo: 'socialapp://login-callback',
        scopes: 'openid profile email',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('Microsoft Sign-In Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      await FacebookAuth.instance.logOut();
      await GoogleSignIn().signOut();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: IncomingLinkClassifier.recoveryRedirectUrl,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
      try {
        await _supabase.auth.signOut(scope: SignOutScope.others);
      } catch (e) {
        debugPrint('⚠️ Could not revoke other sessions: $e');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ───────────────────────── Account security ─────────────────────────

  /// Custom scheme already used (and allow-listed) for OAuth callbacks.
  static const String _accountEmailRedirect = 'socialapp://login-callback';

  /// Verifies [password] WITHOUT touching the app's live session.
  Future<void> _verifyCurrentPassword({
    required String email,
    required String password,
  }) async {
    final verifier = GoTrueClient(
      url: '${AppSecrets.supabaseUrl}/auth/v1',
      headers: {
        'apikey': AppSecrets.supabaseAnonKey,
        'Authorization': 'Bearer ${AppSecrets.supabaseAnonKey}',
      },
      autoRefreshToken: false,
      flowType: AuthFlowType.implicit,
    );
    try {
      await verifier.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      final code = (e.code ?? '').toLowerCase();
      if (code == 'invalid_credentials' ||
          msg.contains('invalid login credentials')) {
        throw const WrongCurrentPasswordException();
      }
      rethrow;
    } finally {
      try {
        await verifier.signOut(scope: SignOutScope.local);
      } catch (_) {}
      verifier.dispose();
    }
  }

  supabase_pkg.User _requireUserWithEmail() {
    final user = _supabase.auth.currentUser;
    final email = user?.email;
    if (user == null || email == null || email.isEmpty) {
      throw AuthException(
        'Your session has expired. Please sign in again.',
        code: 'session_expired',
      );
    }
    return user;
  }

  /// In-app password change. Accounts that already have a password must
  /// prove they know it; OAuth-only accounts may set a first password.
  Future<void> changePassword({
    String? currentPassword,
    required String newPassword,
  }) async {
    final user = _requireUserWithEmail();
    final info = AccountAuthInfo.fromUser(user);

    if (info.hasPassword) {
      if (currentPassword == null || currentPassword.isEmpty) {
        throw const WrongCurrentPasswordException();
      }
      await _verifyCurrentPassword(
        email: user.email!,
        password: currentPassword,
      );
    }

    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword, data: {'has_password': true}),
    );

    try {
      await _supabase.auth.signOut(scope: SignOutScope.others);
    } catch (e) {
      debugPrint('⚠️ Could not revoke other sessions: $e');
    }
  }

  /// Starts a Supabase email change (confirmation link goes out).
  Future<supabase_pkg.User?> changeEmail({
    required String currentPassword,
    required String newEmail,
  }) async {
    final user = _requireUserWithEmail();
    await _verifyCurrentPassword(email: user.email!, password: currentPassword);
    final res = await _supabase.auth.updateUser(
      UserAttributes(email: newEmail.trim()),
      emailRedirectTo: _accountEmailRedirect,
    );
    return res.user;
  }

  /// Re-issues the confirmation email for an already pending change
  /// (the session is already authenticated; no password needed again).
  Future<supabase_pkg.User?> resendEmailChange(String pendingEmail) async {
    _requireUserWithEmail();
    final res = await _supabase.auth.updateUser(
      UserAttributes(email: pendingEmail.trim()),
      emailRedirectTo: _accountEmailRedirect,
    );
    return res.user;
  }

  /// Supabase has no client API to revoke a pending change, so this calls the
  /// `cancel_email_change` RPC (see supabase/cancel_email_change.sql).
  Future<void> cancelEmailChange() async {
    _requireUserWithEmail();
    await _supabase.rpc('cancel_email_change');
  }

  Future<void> resendSignupVerification() async {
    final user = _requireUserWithEmail();
    await _supabase.auth.resend(
      type: OtpType.signup,
      email: user.email!,
      emailRedirectTo: _accountEmailRedirect,
    );
  }

  Future<supabase_pkg.User?> fetchFreshUser() async {
    final res = await _supabase.auth.getUser();
    return res.user;
  }

  /// Best-effort mirror of the confirmed auth email into `users.email`.
  Future<void> syncProfileEmail(String? email) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null || email == null || email.isEmpty) return;
    try {
      await _supabase
          .from(SupabaseConstants.users)
          .update({'email': email})
          .eq(UserColumns.id, uid);
    } catch (e) {
      debugPrint('⚠️ Could not sync profile email: $e');
    }
  }

  @override
  Future<UserData?> getUserData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response =
          await _supabase.from('users').select().eq('id', user.id).single();
      if (response.keys.isEmpty) {
        throw Exception('Failed to fetch user data');
      }
      return UserData.fromMap(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> setUserData(String name, String email, String userId) async {
    try {
      await _supabase.from('users').upsert({
        'name': name,
        'email': email,
        'id': userId,
      });
    } catch (e) {
      debugPrint('Error setting user data: $e');
      rethrow;
    }
  }

  // ───────────────────────── Account deletion ─────────────────────────

  Future<void> verifyCurrentPassword(String password) async {
    final dynamic isValid = await _supabase.rpc(
      SupabaseConstants.verifyCurrentUserPasswordRpc,
      params: {'p_password': password},
    );
    if (isValid != true) {
      throw const AuthException('Incorrect password', code: 'invalid_password');
    }
  }

  Future<void> softDeleteAccount() async {
    if (_supabase.auth.currentUser == null) {
      throw const AuthException('Not authenticated', code: 'not_authenticated');
    }
    await _supabase.rpc(SupabaseConstants.softDeleteUserAccountRpc);
  }

  /// Clears the local session + OAuth provider sessions after the account was
  /// deleted. Uses a LOCAL scope sign-out because every server session was
  /// already wiped by the RPC (a global sign-out would hit a dead session).
  /// Never throws: each step is independent and best-effort.
  Future<void> signOutLocallyAfterDeletion() async {
    try {
      await _supabase.auth.signOut(scope: SignOutScope.local);
    } catch (e) {
      debugPrint('⚠️ Local sign-out after deletion failed: $e');
    }
    try {
      await FacebookAuth.instance.logOut();
    } catch (e) {
      debugPrint('⚠️ Facebook logOut after deletion failed: $e');
    }
    try {
      await GoogleSignIn().signOut();
    } catch (e) {
      debugPrint('⚠️ Google signOut after deletion failed: $e');
    }
  }

  User? fetchRawUser() {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    return user;
  }
}
