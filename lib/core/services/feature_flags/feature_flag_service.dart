import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_media_app/core/observability/build_info.dart';
import 'package:social_media_app/core/services/system_control_service.dart';
import 'package:social_media_app/core/supabase/supabase_provider.dart';
import 'package:uuid/uuid.dart';

import 'feature_flag_evaluator.dart';

/// Calls `get_app_feature_flags`. Injectable so tests never touch Supabase.
typedef FeatureFlagsFetcher = Future<Object?> Function();

// -----------------------------------------------------------------------------
// Persistence
// -----------------------------------------------------------------------------

/// Local persistence for the last good payload and the device install id.
abstract class FeatureFlagStore {
  Future<String?> readSnapshot();
  Future<void> writeSnapshot(String json);

  /// Returns the persisted device install id, creating (uuid v4) and storing it
  /// on first run. This is the bucketing identifier before login.
  Future<String> readOrCreateInstallId();
}

class SharedPrefsFeatureFlagStore implements FeatureFlagStore {
  SharedPrefsFeatureFlagStore({SharedPreferences? prefs}) : _prefs = prefs;

  static const String snapshotKey = 'feature_flags.snapshot.v1';
  static const String installIdKey = 'feature_flags.device_install_id';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _p() async => _prefs ??= await SharedPreferences.getInstance();

  @override
  Future<String?> readSnapshot() async => (await _p()).getString(snapshotKey);

  @override
  Future<void> writeSnapshot(String json) async {
    await (await _p()).setString(snapshotKey, json);
  }

  @override
  Future<String> readOrCreateInstallId() async {
    final p = await _p();
    final existing = p.getString(installIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = const Uuid().v4();
    await p.setString(installIdKey, id);
    return id;
  }
}

/// For tests.
class InMemoryFeatureFlagStore implements FeatureFlagStore {
  InMemoryFeatureFlagStore({this.snapshot, String? installId}) : _installId = installId;

  String? snapshot;
  String? _installId;
  bool failReads = false;

  @override
  Future<String?> readSnapshot() async {
    if (failReads) throw StateError('read failed');
    return snapshot;
  }

  @override
  Future<void> writeSnapshot(String json) async => snapshot = json;

  @override
  Future<String> readOrCreateInstallId() async => _installId ??= const Uuid().v4();
}

// -----------------------------------------------------------------------------
// Payload + snapshot
// -----------------------------------------------------------------------------

class FeatureFlagsPayload {
  const FeatureFlagsPayload({required this.rules, required this.targetedKeys, this.serverTime});

  final Map<String, FeatureFlagRule> rules;
  final Set<String> targetedKeys;
  final DateTime? serverTime;

  /// null unless the payload is a successful `get_app_feature_flags` object.
  static FeatureFlagsPayload? tryParse(Object? raw) {
    if (raw is! Map || raw['ok'] != true) return null;
    final flags = raw['flags'];
    if (flags is! Map) return null;

    final rules = <String, FeatureFlagRule>{};
    flags.forEach((k, v) {
      if (k is! String) return;
      final rule = FeatureFlagRule.tryParse(k, v);
      if (rule != null) rules[k] = rule;
    });

    final targeted = raw['targeted_keys'];
    final st = raw['server_time'];
    return FeatureFlagsPayload(
      rules: rules,
      targetedKeys: targeted is List ? targeted.whereType<String>().toSet() : <String>{},
      serverTime: st is String ? DateTime.tryParse(st)?.toUtc() : null,
    );
  }
}

class FeatureFlagSnapshot {
  const FeatureFlagSnapshot({
    this.rules = const {},
    this.targetedKeys = const {},
    this.targetedForUserId,
    this.fetchedAt,
    this.serverOffset = Duration.zero,
    this.fromCache = false,
  });

  static const FeatureFlagSnapshot empty = FeatureFlagSnapshot();

  final Map<String, FeatureFlagRule> rules;

  /// Flags whose server-side whitelist contained [targetedForUserId].
  final Set<String> targetedKeys;
  final String? targetedForUserId;
  final DateTime? fetchedAt;

  /// serverTime - deviceTime at fetch; corrects a skewed device clock for the
  /// schedule window.
  final Duration serverOffset;
  final bool fromCache;

  FeatureFlagSnapshot withoutTargets() => FeatureFlagSnapshot(
    rules: rules,
    fetchedAt: fetchedAt,
    serverOffset: serverOffset,
    fromCache: fromCache,
  );
}

// -----------------------------------------------------------------------------
// Service
// -----------------------------------------------------------------------------

/// Feature flags with deterministic percentage rollout.
///
/// * Rules come from `public.get_app_feature_flags()` (rules WITHOUT whitelists
///   + the flags whose whitelist contains the caller).
/// * Refreshes: bootstrap, app resume, every [pollInterval] in the foreground,
///   after every sign-in/out ([onAuthChanged]).
/// * FAIL-OPEN OFFLINE: the last good payload is persisted and read on cold
///   start; a network error, timeout or malformed payload keeps the last known
///   state. Unknown flags (never fetched, no cache) evaluate to `defaultValue`.
/// * Evaluation never throws.
///
/// A killed flag is only enforced once a refresh succeeds. A device that stays
/// offline keeps its cached state, see [isStale].
class FeatureFlagService with WidgetsBindingObserver {
  FeatureFlagService({
    FeatureFlagsFetcher? fetcher,
    FeatureFlagStore? store,
    FeatureFlagEvaluator evaluator = const FeatureFlagEvaluator(),
    String? Function()? userId,
    String Function()? platform,
    String Function()? environment,
    String? Function()? appVersion,
    DateTime Function()? now,
    this.minInterval = const Duration(seconds: 15),
    this.timeout = const Duration(seconds: 15),
    this.pollInterval = const Duration(minutes: 5),
    this.staleAfter = const Duration(hours: 24),
  }) : _fetcher = fetcher ?? _rpcFetcher,
       _store = store ?? SharedPrefsFeatureFlagStore(),
       _evaluator = evaluator,
       _userId = userId ?? _supabaseUserId,
       _platform = platform ?? currentPlatformName,
       _environment = environment ?? (() => BuildInfo.environment),
       _appVersion = appVersion ?? SystemControlService.currentAppVersion,
       _now = now ?? DateTime.now;

  static final FeatureFlagService instance = FeatureFlagService();

  final Duration minInterval;
  final Duration timeout;
  final Duration pollInterval;
  final Duration staleAfter;

  final FeatureFlagsFetcher _fetcher;
  final FeatureFlagStore _store;
  final FeatureFlagEvaluator _evaluator;
  final String? Function() _userId;
  final String Function() _platform;
  final String Function() _environment;
  final String? Function() _appVersion;
  final DateTime Function() _now;

  /// Bumped whenever the snapshot changes (rebuild listeners with this).
  final ValueNotifier<int> revision = ValueNotifier(0);

  FeatureFlagSnapshot _snapshot = FeatureFlagSnapshot.empty;
  String? _installId;
  bool _ready = false;
  Future<void>? _initFuture;
  Future<void>? _inFlight;
  bool _rerunForced = false;
  DateTime? _lastAttempt;
  Timer? _pollTimer;
  bool _observing = false;

  FeatureFlagSnapshot get snapshot => _snapshot;
  bool get isReady => _ready;

  /// True when the data is older than [staleAfter] (or never fetched).
  bool get isStale {
    final at = _snapshot.fetchedAt;
    return at == null || _now().difference(at) > staleAfter;
  }

  /// Idempotent. Awaits ONLY local storage (install id + cache); the first
  /// network refresh is fire-and-forget, so an offline cold start is never
  /// delayed.
  Future<void> init() => _initFuture ??= _doInit();

  Future<void> _doInit() async {
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
    _startPolling();

    try {
      _installId = await _store.readOrCreateInstallId();
    } catch (e) {
      // Storage broken: fall back to a per-session id (not stable across restarts).
      _installId = const Uuid().v4();
      debugPrint('[FeatureFlags] install id unavailable, using session id: $e');
    }

    try {
      _applyCache(await _store.readSnapshot());
    } catch (e) {
      debugPrint('[FeatureFlags] cache read failed (starting empty): $e');
    }

    _ready = true;
    _bump();
    unawaited(refresh(force: true));
  }

  void dispose() {
    if (_observing) {
      WidgetsBinding.instance.removeObserver(this);
      _observing = false;
    }
    _pollTimer?.cancel();
  }

  // -- Evaluation -------------------------------------------------------------

  /// Never throws. [defaultValue] applies to flags we have no rule for.
  bool isEnabled(String key, {bool defaultValue = false}) {
    final rule = _snapshot.rules[key];
    if (!_ready || rule == null) return defaultValue;
    try {
      return _evaluator.evaluate(rule, _context(), whitelisted: _isWhitelisted(key));
    } catch (_) {
      return rule.defaultFallback;
    }
  }

  /// Decision + reason + bucket, for debug screens and support.
  FeatureFlagDecision? explain(String key) {
    final rule = _snapshot.rules[key];
    if (!_ready || rule == null) return null;
    return _evaluator.evaluateDetailed(rule, _context(), whitelisted: _isWhitelisted(key));
  }

  Map<String, bool> evaluateAll() => {
    for (final key in _snapshot.rules.keys) key: isEnabled(key),
  };

  bool _isWhitelisted(String key) {
    final uid = _userId();
    return uid != null &&
        uid.isNotEmpty &&
        _snapshot.targetedForUserId == uid &&
        _snapshot.targetedKeys.contains(key);
  }

  FeatureFlagContext _context() {
    final uid = _userId();
    final identifier = (uid != null && uid.isNotEmpty) ? uid : (_installId ?? '');
    return FeatureFlagContext(
      platform: _platform(),
      environment: _environment(),
      appVersion: _appVersion(),
      identifier: identifier,
      now: _now().toUtc().add(_snapshot.serverOffset),
    );
  }

  // -- Refresh ----------------------------------------------------------------

  /// Sign-in / sign-out: whitelists and the bucketing identifier are per-user.
  void onAuthChanged() {
    final uid = _userId();
    if (_snapshot.targetedForUserId != null && _snapshot.targetedForUserId != uid) {
      _snapshot = _snapshot.withoutTargets();
      unawaited(_persist());
    }
    _bump();
    unawaited(refresh(force: true));
  }

  /// Never throws. Single-flight; a forced call during a run schedules one more.
  Future<void> refresh({bool force = false}) {
    final running = _inFlight;
    if (running != null) {
      if (force) _rerunForced = true;
      return running;
    }
    final last = _lastAttempt;
    if (!force && last != null && _now().difference(last) < minInterval) {
      return Future<void>.value();
    }
    final future = _fetchOnce().whenComplete(() {
      _inFlight = null;
      if (_rerunForced) {
        _rerunForced = false;
        unawaited(refresh(force: true));
      }
    });
    _inFlight = future;
    return future;
  }

  Future<void> _fetchOnce() async {
    _lastAttempt = _now();
    final userAtRequest = _userId();
    try {
      final raw = await _fetcher().timeout(timeout);
      final payload = FeatureFlagsPayload.tryParse(raw);
      if (payload == null) {
        debugPrint('[FeatureFlags] ignored malformed payload');
        return;
      }
      final deviceNow = _now().toUtc();
      final server = payload.serverTime;
      _snapshot = FeatureFlagSnapshot(
        rules: payload.rules,
        targetedKeys: userAtRequest == null ? const {} : payload.targetedKeys,
        targetedForUserId: userAtRequest,
        fetchedAt: deviceNow,
        serverOffset: server == null ? _snapshot.serverOffset : server.difference(deviceNow),
      );
      _bump();
      unawaited(_persist());
    } catch (e) {
      debugPrint('[FeatureFlags] fetch failed (keeping last known): $e');
    }
  }

  // -- Cache ------------------------------------------------------------------

  Future<void> _persist() async {
    try {
      final s = _snapshot;
      await _store.writeSnapshot(
        jsonEncode({
          'v': 1,
          'fetched_at': s.fetchedAt?.toIso8601String(),
          'server_offset_ms': s.serverOffset.inMilliseconds,
          'flags': {for (final e in s.rules.entries) e.key: e.value.toJson()},
          'targeted': {'user_id': s.targetedForUserId, 'keys': s.targetedKeys.toList()},
          // Informational (diagnostics): evaluation is always recomputed from the rules.
          'evaluated': _ready ? evaluateAll() : const <String, bool>{},
        }),
      );
    } catch (e) {
      debugPrint('[FeatureFlags] cache write failed: $e');
    }
  }

  void _applyCache(String? raw) {
    if (raw == null) return;
    try {
      final map = jsonDecode(raw);
      if (map is! Map || map['v'] != 1) return;
      final flags = map['flags'];
      if (flags is! Map) return;

      final rules = <String, FeatureFlagRule>{};
      flags.forEach((k, v) {
        if (k is! String) return;
        final rule = FeatureFlagRule.tryParse(k, v);
        if (rule != null) rules[k] = rule;
      });

      final targeted = map['targeted'];
      final cachedUser = targeted is Map ? targeted['user_id'] : null;
      final keys = targeted is Map && targeted['keys'] is List
          ? (targeted['keys'] as List).whereType<String>().toSet()
          : <String>{};
      final currentUser = _userId();
      // Whitelist hits belong to the user they were fetched for.
      final keep = cachedUser is String && cachedUser == currentUser;

      final fetched = map['fetched_at'];
      final offsetMs = map['server_offset_ms'];
      _snapshot = FeatureFlagSnapshot(
        rules: rules,
        targetedKeys: keep ? keys : const {},
        targetedForUserId: keep ? cachedUser : null,
        fetchedAt: fetched is String ? DateTime.tryParse(fetched)?.toUtc() : null,
        serverOffset: Duration(milliseconds: offsetMs is num ? offsetMs.round() : 0),
        fromCache: true,
      );
    } catch (e) {
      debugPrint('[FeatureFlags] ignored corrupt cache: $e');
    }
  }

  // -- Plumbing ---------------------------------------------------------------

  void _bump() => revision.value++;

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(pollInterval, (_) => unawaited(refresh()));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _startPolling();
        unawaited(refresh());
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _pollTimer?.cancel();
        break;
      default:
        break;
    }
  }

  static String? _supabaseUserId() {
    try {
      return SupabaseProvider.idOrNull;
    } catch (_) {
      return null;
    }
  }

  static Future<Object?> _rpcFetcher() => SupabaseProvider.client.rpc('get_app_feature_flags');
}

/// `android` | `ios` | `web` | `windows` | `macos` | `linux`
String currentPlatformName() {
  if (kIsWeb) return 'web';
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return 'android';
    case TargetPlatform.iOS:
      return 'ios';
    case TargetPlatform.windows:
      return 'windows';
    case TargetPlatform.macOS:
      return 'macos';
    case TargetPlatform.linux:
      return 'linux';
    case TargetPlatform.fuchsia:
      return 'linux';
  }
}
