import 'dart:async';
import 'dart:convert';
import 'package:app_links/app_links.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/deep_link/services/incoming_link_classifier.dart';
import '../../../core/notifications/notification_navigator_key.dart';
import '../../../core/observability/observability.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/services/active_screen_tracker.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/toast/app_toast.dart';
import 'auth_recovery_coordinator.dart';
import 'package:social_media_app/core/localization/app_l10n.dart';

/// Result of a link the auth flow rejected (expired, already used, ...).
class AuthLinkProblem {
  final String code;
  const AuthLinkProblem(this.code);
}

/// Single owner of every authentication deep link.
///
/// Responsibilities
///  1. Recognise auth links BEFORE anything else reacts to them (the share
///     intent pipeline ignores them through `IncomingLinkClassifier`).
///  2. Verify `https://<host>/auth/recovery#token_hash=...&type=recovery`
///     links with `verifyOTP` (works from any device, unlike PKCE `code`).
///  3. Turn error links (`otp_expired`, ...) into one clear screen instead of
///     an unexplained toast.
///  4. Expose [isBusy] / [waitUntilSettled] so Splash does not pick a route
///     while a link is still being verified.

class AuthLinkHandler {
  AuthLinkHandler._();
  static final AuthLinkHandler instance = AuthLinkHandler._();

  static const Duration _busyTimeout = Duration(seconds: 8);
  static const String _kLastInitialFpKey = 'auth_link_last_initial_fp';

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  bool _initialized = false;

  Completer<void>? _settled;
  Timer? _busyTimer;
  int _busyCount = 0;

  String? _lastFp;
  DateTime? _lastFpAt;

  AuthLinkProblem? _pendingProblem;
  DateTime? _lastProblemAt;

  bool get isBusy => _settled != null;

  /// True while Supabase may still emit an error caused by a link we already
  /// explained to the user (prevents a second, cryptic toast).
  bool get shouldSuppressAuthErrors {
    if (isBusy) return true;
    final at = _lastProblemAt;
    return at != null &&
        DateTime.now().difference(at) < const Duration(seconds: 3);
  }

  Future<void> waitUntilSettled() {
    final c = _settled;
    if (c == null) return Future<void>.value();
    return c.future.timeout(_busyTimeout, onTimeout: () {});
  }

  /// Splash consumes this once to route to the "link expired" screen.
  AuthLinkProblem? takePendingProblem() {
    final p = _pendingProblem;
    _pendingProblem = null;
    return p;
  }

  /// Called by the auth listener on `passwordRecovery` / `signedIn`.
  void onAuthEvent() => _endBusy(force: true);

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    _sub = _appLinks.uriLinkStream.listen(
      (uri) => unawaited(_handle(uri, coldStart: false)),
      onError: (Object e) => debugPrint('⚠️ AuthLinkHandler stream error: $e'),
    );

    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) unawaited(_handle(initial, coldStart: true));
    } catch (e) {
      debugPrint('⚠️ AuthLinkHandler initial link error: $e');
    }
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _initialized = false;
    _endBusy(force: true);
  }

  // ─── core ────────────────────────────────────────────────────────────────

  Future<void> _handle(Uri uri, {required bool coldStart}) async {
    if (IncomingLinkClassifier.classifyUri(uri) !=
        IncomingLinkKind.authCallback) {
      return;
    }

    // Synchronous on purpose: from this line on, Splash / share flow see "busy".
    _beginBusy();

    final fp = _fingerprint(uri);
    var keepBusy = false;
    try {
      if (_isRecentDuplicate(fp)) return;
      if (coldStart && await _wasAlreadyConsumedAsInitial(fp)) return;
      if (coldStart) await _rememberInitial(fp);

      final error = IncomingLinkClassifier.parseError(uri);
      if (error != null) {
        await _reportProblem(error.code);
        return;
      }

      final params = IncomingLinkClassifier.params(uri);
      final tokenHash = params['token_hash'];
      if (params['type'] == 'recovery' &&
          tokenHash != null &&
          tokenHash.isNotEmpty) {
        await _verifyRecovery(tokenHash);
        return;
      }

      keepBusy = true;
      await obs.breadcrumb('auth callback received', feature: 'auth');
    } finally {
      if (!keepBusy) _endBusy();
    }
  }

  Future<void> _verifyRecovery(String tokenHash) async {
    AuthRecoveryCoordinator.markRecoveryPending();
    try {
      final res = await SupabaseProvider.auth.verifyOTP(
        tokenHash: tokenHash,
        type: OtpType.recovery,
      );
      if (res.session == null) {
        await _reportProblem('otp_expired');
        return;
      }
      await obs.breadcrumb('recovery link verified', feature: 'auth');
      await _openResetPasswordIfNeeded();
    } on AuthRetryableFetchException {
      AuthRecoveryCoordinator.consumeRecovery();
      AppToast.error(AppL10n.current.noConnectionCheckYour);
    } on AuthException catch (e) {
      await _reportProblem(e.code ?? e.statusCode ?? 'invalid_link');
    } catch (e, s) {
      AuthRecoveryCoordinator.consumeRecovery();
      unawaited(
        obs.recordError(
          e,
          s,
          feature: 'auth',
          operation: 'verify_recovery_link',
          reason: 'unexpected failure while verifying recovery link',
        ),
      );
      AppToast.error(AppL10n.current.somethingWentWrongPlease2);
    }
  }

  /// `verifyOTP` normally emits `passwordRecovery`, and the bootstrap listener
  /// navigates. This is the safety net in case that event did not navigate.
  Future<void> _openResetPasswordIfNeeded() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final route = ActiveScreenTracker.currentRoute;
    if (route == AppRoutes.splashViewRoute ||
        route == AppRoutes.resetPasswordRoute) {
      return; // Splash will route to reset because the flag is set.
    }
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      AppRoutes.resetPasswordRoute,
      (r) => false,
    );
  }

  Future<void> _reportProblem(String code) async {
    AuthRecoveryCoordinator.consumeRecovery();
    _lastProblemAt = DateTime.now();
    unawaited(obs.breadcrumb('auth link rejected: $code', feature: 'auth'));

    final nav = navigatorKey.currentState;
    final route = ActiveScreenTracker.currentRoute;
    if (nav == null || route == AppRoutes.splashViewRoute) {
      _pendingProblem = AuthLinkProblem(code);
      return;
    }
    nav.pushNamedAndRemoveUntil(
      AppRoutes.authLinkExpiredRoute,
      (r) => false,
      arguments: code,
    );
  }

  // ─── busy bookkeeping ────────────────────────────────────────────────────

  void _beginBusy() {
    _busyCount++;
    _settled ??= Completer<void>();
    _busyTimer?.cancel();
    _busyTimer = Timer(_busyTimeout, () => _endBusy(force: true));
  }

  /// Each `_handle` pairs one begin with one end, so a duplicate delivery
  /// cannot release the app while the first verification is still running.
  /// `force` is for the auth event and the safety timeout.
  void _endBusy({bool force = false}) {
    if (force) {
      _busyCount = 0;
    } else if (_busyCount > 0) {
      _busyCount--;
    }
    if (_busyCount > 0) return;
    _busyTimer?.cancel();
    _busyTimer = null;
    final c = _settled;
    _settled = null;
    if (c != null && !c.isCompleted) c.complete();
  }

  // ─── de-duplication (fingerprints only, never the URL) ───────────────────

  String _fingerprint(Uri uri) =>
      sha256.convert(utf8.encode(uri.toString())).toString();

  bool _isRecentDuplicate(String fp) {
    final now = DateTime.now();
    final dup =
        _lastFp == fp &&
        _lastFpAt != null &&
        now.difference(_lastFpAt!) < const Duration(seconds: 5);
    _lastFp = fp;
    _lastFpAt = now;
    return dup;
  }

  /// Android re-delivers the ORIGINAL launch intent when the process is
  /// recreated from Recents / hot restart. Without this a consumed one-time
  /// token would show "link expired" on every restart.
  Future<bool> _wasAlreadyConsumedAsInitial(String fp) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLastInitialFpKey) == fp;
  }

  Future<void> _rememberInitial(String fp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastInitialFpKey, fp);
  }
}
