import 'dart:io' show SocketException;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../models/two_factor_enrollment.dart';
import '../models/two_factor_failure.dart';
import '../models/two_factor_status.dart';

/// The ONLY file in the two_factor feature that talks to `supabase.auth.mfa`
/// and the recovery-code RPCs. Every public method throws [TwoFactorFailure]
/// and nothing else, so cubits and views never import the SDK.
class TwoFactorService {
  const TwoFactorService();

  // ───────────────────────── status ─────────────────────────

  /// Server truth when online, the locally persisted user when offline.
  Future<TwoFactorStatus> status() async {
    User? user;
    try {
      user = (await SupabaseProvider.auth.getUser()).user;
    } catch (_) {
      user = SupabaseProvider.user;
    }
    return _verifiedTotp(user) == null
        ? TwoFactorStatus.disabled
        : TwoFactorStatus.enabled;
  }

  /// Id of the verified TOTP factor, needed to disable it.
  String? get verifiedFactorId => _verifiedTotp(SupabaseProvider.user)?.id;

  // ───────────────────────── enrollment ─────────────────────────

  Future<TwoFactorEnrollment> beginEnrollment() => _guard(() async {
    await _dropStaleUnverifiedFactors();
    final res = await SupabaseProvider.auth.mfa.enroll(
      factorType: FactorType.totp,
      issuer: 'Social Mate',
      friendlyName: 'authenticator-${DateTime.now().millisecondsSinceEpoch}',
    );
    final totp = res.totp;
    if (totp == null) throw const TwoFactorFailure.unknown();
    return TwoFactorEnrollment(
      factorId: res.id,
      qrSvg: _rawSvg(totp.qrCode),
      secret: totp.secret,
      otpauthUri: totp.uri,
    );
  });

  /// Verifies the first code. On success the session is upgraded to aal2.
  Future<void> confirmEnrollment(String factorId, String code) => _guard(
    () => SupabaseProvider.auth.mfa.challengeAndVerify(
      factorId: factorId,
      code: code,
    ),
  );

  /// Abandoning the wizard before verification: best effort, never throws.
  Future<void> cancelEnrollment(String factorId) async {
    try {
      await SupabaseProvider.auth.mfa.unenroll(factorId);
    } catch (_) {}
  }

  /// Requires an aal2 session (the server enforces it). Returns the plaintext
  /// codes ONCE; only bcrypt hashes are stored.
  Future<List<String>> generateRecoveryCodes() => _guard(() async {
    final res = await SupabaseProvider.client.rpc(
      'generate_mfa_recovery_codes',
    );
    return (res as List).cast<String>();
  });

  Future<int> recoveryCodesRemaining() => _guard(() async {
    final res = await SupabaseProvider.client.rpc(
      'mfa_recovery_codes_remaining',
    );
    return (res as num).toInt();
  });

  // ───────────────────────── login challenge ─────────────────────────

  Future<void> verifyLoginCode(String code) => _guard(() async {
    final factorId = verifiedFactorId;
    if (factorId == null) throw const TwoFactorFailure.noFactor();
    await SupabaseProvider.auth.mfa.challengeAndVerify(
      factorId: factorId,
      code: code,
    );
  });

  /// Success REMOVES the TOTP factor (Supabase cannot mint aal2 from a code),
  /// so the caller must tell the user to set 2FA up again.
  Future<RedeemResult> redeemBackupCode(String code) => _guard(() async {
    final res = await SupabaseProvider.client.rpc(
      'redeem_mfa_recovery_code',
      params: {'p_code': code},
    );
    final result = RedeemResult.fromJson(Map<String, dynamic>.from(res as Map));
    if (result.ok) {
      // Pull the new user (no factors) and a fresh token.
      await SupabaseProvider.auth.refreshSession();
      try {
        await SupabaseProvider.auth.signOut(scope: SignOutScope.others);
      } catch (_) {}
    }
    return result;
  });

  // ───────────────────────── disable ─────────────────────────

  /// Needs an aal2 session. Identity must already have been re-checked by the
  /// caller (password or live TOTP).
  Future<void> disable() => _guard(() async {
    final factorId = verifiedFactorId;
    if (factorId == null) throw const TwoFactorFailure.noFactor();
    await SupabaseProvider.auth.mfa.unenroll(factorId);
    await SupabaseProvider.client.rpc('clear_mfa_recovery_codes');
    await SupabaseProvider.auth.refreshSession();
  });

  /// Re-checks the signed-in user's password through the existing RPC.
  Future<void> verifyPassword(String password) => _guard(() async {
    final ok = await SupabaseProvider.client.rpc(
      'verify_current_user_password',
      params: {'p_password': password},
    );
    if (ok != true) {
      throw const TwoFactorFailure(
        TwoFactorFailureKind.invalidCode,
        'Incorrect password.',
      );
    }
  });

  // ───────────────────────── helpers ─────────────────────────

  Factor? _verifiedTotp(User? u) =>
      (u?.factors ?? const [])
          .where((f) => f.status.toString().endsWith('verified'))
          .firstOrNull;

  Future<void> _dropStaleUnverifiedFactors() async {
    try {
      final user = (await SupabaseProvider.auth.getUser()).user;
      for (final f in user?.factors ?? const <Factor>[]) {
        if (!f.status.toString().endsWith('verified')) {
          await SupabaseProvider.auth.mfa.unenroll(f.id);
        }
      }
    } catch (_) {
      // A leftover factor only matters if enroll() then fails, and that error
      // is reported on its own.
    }
  }

  /// Accepts both a raw `<svg>` string and a `data:image/svg+xml,...` URI.
  String _rawSvg(String q) =>
      q.startsWith('data:')
          ? Uri.decodeComponent(q.substring(q.indexOf(',') + 1))
          : q;

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on TwoFactorFailure {
      rethrow;
    } catch (e) {
      throw mapError(e);
    }
  }

  /// Visible for testing.
  static TwoFactorFailure mapError(Object e) {
    if (e is SocketException) {
      return const TwoFactorFailure(
        TwoFactorFailureKind.offline,
        'No internet connection. Please check your network.',
      );
    }

    if (e is AuthException) {
      final code = (e.code ?? '').toLowerCase();
      final msg = e.message.toLowerCase();

      if (code == 'mfa_verification_failed' ||
          code == 'mfa_verification_rejected' ||
          msg.contains('invalid totp')) {
        return const TwoFactorFailure(
          TwoFactorFailureKind.invalidCode,
          'That code is incorrect or expired. Try the next code.',
        );
      }
      if (code == 'mfa_challenge_expired') {
        return const TwoFactorFailure(
          TwoFactorFailureKind.challengeExpired,
          'The verification expired. Please try again.',
        );
      }
      if (code == 'insufficient_aal') {
        return const TwoFactorFailure(
          TwoFactorFailureKind.aalRequired,
          'Please confirm with your authenticator code first.',
        );
      }
      if (code == 'over_request_rate_limit' ||
          code == 'over_email_send_rate_limit' ||
          msg.contains('rate limit')) {
        return const TwoFactorFailure(
          TwoFactorFailureKind.rateLimited,
          'Too many attempts. Please wait a moment and try again.',
        );
      }
      if (code == 'mfa_totp_enroll_not_enabled' ||
          code == 'mfa_totp_verify_not_enabled') {
        return const TwoFactorFailure(
          TwoFactorFailureKind.notEnabledOnProject,
          'Two-factor authentication is not available right now.',
        );
      }
      if (msg.contains('socketexception') ||
          msg.contains('failed host lookup')) {
        return const TwoFactorFailure(
          TwoFactorFailureKind.offline,
          'No internet connection. Please check your network.',
        );
      }
    }

    if (e is PostgrestException) {
      if (e.code == '42501') {
        return const TwoFactorFailure(
          TwoFactorFailureKind.aalRequired,
          'Please confirm with your authenticator code first.',
        );
      }
      if (e.code == 'P0002') return const TwoFactorFailure.noFactor();
    }

    return const TwoFactorFailure.unknown();
  }
}
