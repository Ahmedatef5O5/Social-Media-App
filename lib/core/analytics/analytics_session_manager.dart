import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

import 'analytics_queue.dart' show AnalyticsStorage;

/// Owns the two identifiers every event carries.
///
///  * `anonymousId` — `SHA-256(installToken)` in lowercase hex. The install
///    token is 32 random bytes generated once per install and kept only in
///    local storage; the raw token is NEVER sent anywhere, so the id cannot be
///    reversed to a device and a reinstall produces a new, unrelated id.
///  * `sessionId` — a fresh UUID v4 per app *foreground session*. Returning to
///    the app within [inactivityGrace] (permission dialog, share sheet, quick
///    app switch) continues the same session instead of inflating session
///    counts.
class AnalyticsSessionManager {
  AnalyticsSessionManager({
    required AnalyticsStorage storage,
    DateTime Function()? now,
    Random? random,
    Uuid uuid = const Uuid(),
    this.inactivityGrace = const Duration(seconds: 30),
    this.tokenStorageKey = 'analytics.install_token.v1',
  }) : _storage = storage,
       _now = now ?? DateTime.now,
       _random = random,
       _uuid = uuid;

  final Duration inactivityGrace;
  final String tokenStorageKey;

  final AnalyticsStorage _storage;
  final DateTime Function() _now;
  final Random? _random;
  final Uuid _uuid;

  String? _anonymousId;
  String? _sessionId;
  DateTime? _backgroundedAt;

  bool get isInitialized => _anonymousId != null;

  String get anonymousId {
    final id = _anonymousId;
    if (id == null) {
      throw StateError('AnalyticsSessionManager.init() has not completed');
    }
    return id;
  }

  /// Current session id, or `null` before the first [onForeground].
  String? get sessionId => _sessionId;

  /// Loads (or creates) the install token and derives [anonymousId].
  Future<void> init() async {
    var token = await _storage.read(tokenStorageKey);
    if (token == null || token.length < 32) {
      token = _newToken();
      await _storage.write(tokenStorageKey, token);
    }
    _anonymousId = hashToken(token);
  }

  /// Forgets the current identity and creates a new, unrelated one. Used when
  /// the user turns analytics off and back on.
  Future<void> resetIdentity() async {
    await _storage.delete(tokenStorageKey);
    _sessionId = null;
    _backgroundedAt = null;
    await init();
  }

  /// Call when the app comes to the foreground (and once at start-up).
  /// Returns `true` when a NEW session began — the caller then emits
  /// `app_session_started`.
  bool onForeground() {
    final left = _backgroundedAt;
    _backgroundedAt = null;
    final hasSession = _sessionId != null;
    final withinGrace = left != null && _now().difference(left) < inactivityGrace;
    if (hasSession && withinGrace) return false;
    if (hasSession && left == null) return false; // duplicate "resumed" signal
    _sessionId = _uuid.v4();
    return true;
  }

  /// Call when the app goes to the background.
  void onBackground() {
    _backgroundedAt ??= _now();
  }

  static String hashToken(String token) =>
      sha256.convert(utf8.encode(token)).toString();

  String _newToken() {
    final rng = _random ?? Random.secure();
    final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
