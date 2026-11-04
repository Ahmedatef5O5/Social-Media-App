import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../observability/build_info.dart';
import '../observability/crash_reporter.dart';
import '../observability/error_category.dart';
import '../supabase/supabase_provider.dart';
import 'interceptors/startup_tracker.dart';

/// Delivers one session heartbeat. Default: `rpc('session_heartbeat')`.
typedef SessionTransport =
    Future<void> Function(
      String sessionId,
      int? startupMs,
      Map<String, dynamic> meta,
    );

typedef SessionIdGenerator = String Function();

/// Calls [callback] every [interval]; returns a canceller. Injectable.
typedef PeriodicScheduler =
    void Function() Function(Duration interval, void Function() callback);

/// RFC 4122 version-4 UUID from a CSPRNG. Not derived from user or device.
String generateSessionId([Random? random]) {
  final r = random ?? Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40; // version 4
  b[8] = (b[8] & 0x3f) | 0x80; // variant 10xx
  String h(int i) => b[i].toRadixString(16).padLeft(2, '0');
  return '${h(0)}${h(1)}${h(2)}${h(3)}-${h(4)}${h(5)}-${h(6)}${h(7)}-'
      '${h(8)}${h(9)}-${h(10)}${h(11)}${h(12)}${h(13)}${h(14)}${h(15)}';
}

/// Tiny persistence port: one JSON string. Lets the next launch discover that
/// the previous process died while the app was in the foreground.
abstract class SessionStore {
  Future<String?> read();
  Future<void> write(String value);
}

class SharedPreferencesSessionStore implements SessionStore {
  static const String key = 'perf_session_record_v1';

  @override
  Future<String?> read() async =>
      (await SharedPreferences.getInstance()).getString(key);

  @override
  Future<void> write(String value) async {
    await (await SharedPreferences.getInstance()).setString(key, value);
  }
}

class InMemorySessionStore implements SessionStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String v) async => value = v;
}

/// Detects a blocked main isolate: if two consecutive periodic ticks are
/// >= [threshold] apart while the app is in the foreground, the UI was frozen
/// for that long.
///
/// This is the Dart-visible PROXY for an Android ANR (input dispatch blocked
/// for 5 s). Native ANRs that never reach Dart are only visible in Play Console
/// / Crashlytics ANR reports (Type B, see native_setup).
class MainIsolateStallDetector {
  MainIsolateStallDetector({
    required this.onStall,
    this.interval = const Duration(seconds: 1),
    this.threshold = const Duration(seconds: 5),
    DateTime Function()? now,
    PeriodicScheduler? scheduler,
  }) : _now = now ?? DateTime.now,
       _scheduler = scheduler ?? _timer;

  final void Function(Duration stalledFor) onStall;
  final Duration interval;
  final Duration threshold;
  final DateTime Function() _now;
  final PeriodicScheduler _scheduler;

  void Function()? _cancel;
  DateTime? _last;
  bool _active = false;

  bool get isRunning => _cancel != null;

  void start() {
    if (_cancel != null) return;
    _last = _now();
    _active = true;
    _cancel = _scheduler(interval, tick);
  }

  /// Background: timers are throttled by the OS, a gap there is NOT a freeze.
  void pause() => _active = false;

  /// Foreground again: restart the baseline so the time spent in background is
  /// never reported as a stall.
  void resume() {
    _active = true;
    _last = _now();
  }

  void stop() {
    _cancel?.call();
    _cancel = null;
    _active = false;
  }

  @visibleForTesting
  void tick() {
    final now = _now();
    final last = _last;
    _last = now;
    if (!_active || last == null) return;
    final gap = now.difference(last);
    if (gap >= threshold) onStall(gap);
  }

  static void Function() _timer(Duration interval, void Function() callback) {
    final t = Timer.periodic(interval, (_) => callback());
    return t.cancel;
  }
}

class _Pending {
  _Pending(this.id, this.startupMs, this.meta);

  final String id;
  final int? startupMs;
  final Map<String, dynamic> meta;

  Map<String, dynamic> toJson() => {'id': id, 'startup_ms': startupMs, 'meta': meta};

  static _Pending? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final meta = raw['meta'];
    if (id is! String || meta is! Map) return null;
    final s = raw['startup_ms'];
    return _Pending(id, s is int ? s : null, Map<String, dynamic>.from(meta));
  }
}

/// Owns the app SESSION: a random UUID that rotates on every launch and after
/// [sessionTimeout] in background, reported to `public.session_heartbeat`.
///
/// WHAT IT REPORTS (all flags are monotonic on the server)
///  * base meta: app version/build, platform, OS string  (never user data);
///  * startup duration + kind (cold/warm), from [StartupTracker];
///  * `crashed`  — live (a FATAL report passed through [SessionCrashReporter])
///                 or discovered on the next launch (previous session was still
///                 in the FOREGROUND when its process died);
///  * `anr`      — [MainIsolateStallDetector] saw a >= 5 s freeze.
///
/// DELIVERY: heartbeats need a signed-in user. Until then, or while offline,
/// the session stays "dirty" and is re-sent on resume / sign-in / next call to
/// [syncNow]. Reports about a PREVIOUS session survive restarts (persisted, max
/// 10), so a crash discovered on launch is never lost.
///
/// Pure Dart: Shorebird Type A.
class SessionManager with WidgetsBindingObserver {
  SessionManager({
    SessionStore? store,
    SessionTransport? transport,
    SessionIdGenerator? idGenerator,
    DateTime Function()? now,
    bool Function()? isSignedIn,
    Map<String, dynamic> Function()? deviceMeta,
    this.sessionTimeout = const Duration(minutes: 30),
    StartupTracker? startup,
    MainIsolateStallDetector? stallDetector,
    bool? enabled,
    this.onBackground,
  }) : _store = store ?? SharedPreferencesSessionStore(),
       _transport = transport ?? _rpcTransport,
       _idGenerator = idGenerator ?? generateSessionId,
       _now = now ?? DateTime.now,
       _isSignedIn = isSignedIn ?? (() => SupabaseProvider.isAuthenticated),
       _deviceMeta = deviceMeta ?? defaultDeviceMeta,
       _startup = startup ?? StartupTracker.instance,
       _enabled = enabled ?? _defaultEnabled {
    _stall =
        stallDetector ??
        MainIsolateStallDetector(onStall: (_) => markAnr(), now: _now);
  }

  static final SessionManager instance = SessionManager();

  static final bool _defaultEnabled =
      !kDebugMode || const bool.fromEnvironment('PERF_TELEMETRY');

  static const int maxPending = 10;

  final SessionStore _store;
  final SessionTransport _transport;
  final SessionIdGenerator _idGenerator;
  final DateTime Function() _now;
  final bool Function() _isSignedIn;
  final Map<String, dynamic> Function() _deviceMeta;
  final Duration sessionTimeout;
  final StartupTracker _startup;
  late final MainIsolateStallDetector _stall;
  final bool _enabled;

  /// Called when the app goes to background (flush the other telemetry here).
  void Function()? onBackground;

  String _sessionId = '';
  bool _started = false;
  bool _foreground = true;
  DateTime? _backgroundedAt;

  bool _crashed = false;
  bool _crashForeground = false;
  bool _anr = false;
  int? _startupMs;
  String? _startupKind;
  bool _dirty = false;
  int _version = 0;
  bool _syncing = false;
  bool _resync = false;
  StartupSample? _earlyStartup;

  final List<_Pending> _pending = [];
  Future<void> _writeChain = Future<void>.value();

  /// Current session id (empty until [start] ran).
  String get sessionId => _sessionId;
  bool get isForeground => _foreground;
  bool get hasCrashed => _crashed;
  bool get hasAnr => _anr;
  bool get isDirty => _dirty;
  int get pendingReports => _pending.length;

  // ── Lifecycle ──────────────────────────────────────────────────────────

  /// Call once, after observability is attached. Safe to call twice.
  Future<void> start() async {
    if (_started || !_enabled) return;
    _started = true;

    await _recoverPreviousSession();

    _sessionId = _idGenerator();
    _foreground = true;
    _resetFlags();
    _dirty = true;
    final early = _earlyStartup;
    if (early != null) {
      _earlyStartup = null;
      _applyStartup(early);
    }
    _persist();

    WidgetsBinding.instance.addObserver(this);
    _startup.onMeasured = reportStartup;
    _stall.start();
    unawaited(syncNow());
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stall.stop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_started) return;
    switch (state) {
      case AppLifecycleState.resumed:
        _onResumed();
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _onBackgrounded();
      case AppLifecycleState.inactive:
        break; // transient (permission dialog, notification shade)
    }
  }

  void _onBackgrounded() {
    if (!_foreground) return;
    _foreground = false;
    _backgroundedAt = _now();
    _stall.pause();
    _persist(); // from now on a death is NOT a foreground crash
    try {
      onBackground?.call();
    } catch (_) {}
    unawaited(syncNow());
  }

  void _onResumed() {
    _foreground = true;
    _stall.resume();
    final since = _backgroundedAt;
    _backgroundedAt = null;
    if (since != null && _now().difference(since) >= sessionTimeout) {
      _rotate();
    } else {
      _persist();
    }
    unawaited(syncNow());
  }

  /// Ends the current session and starts a new one (resume after a long stay
  /// in background). The new session's startup is the warm resume->frame time.
  void _rotate() {
    _enqueuePending(_Pending(_sessionId, null, {'ended': true}));
    _sessionId = _idGenerator();
    _resetFlags();
    _dirty = true;
    _version++;
    _persist();
    _startup.measureNextFrame(StartupKind.warm);
  }

  // ── Inputs ─────────────────────────────────────────────────────────────

  /// Wired to [StartupTracker.onMeasured]. A cold sample can arrive BEFORE
  /// [start] (first frame precedes the async bootstrap): it is kept and applied.
  void reportStartup(StartupSample sample) {
    if (!_enabled) return;
    if (!_started) {
      _earlyStartup ??= sample;
      return;
    }
    if (_startupMs != null) return; // first sample of a session wins
    _applyStartup(sample);
    _persist();
    unawaited(syncNow());
  }

  void _applyStartup(StartupSample s) {
    _startupMs = s.milliseconds;
    _startupKind = s.kind.wire;
    _dirty = true;
    _version++;
  }

  /// A fatal error was reported for the running session.
  void markCrashed({bool? foreground}) {
    if (!_started) return;
    _crashed = true;
    _crashForeground = _crashForeground || (foreground ?? _foreground);
    _dirty = true;
    _version++;
    _persist();
    unawaited(syncNow()); // the process may be about to die: try right now
  }

  /// The main isolate was frozen for >= 5 s.
  void markAnr() {
    if (!_started) return;
    _anr = true;
    _dirty = true;
    _version++;
    _persist();
    unawaited(syncNow());
  }

  // ── Delivery ───────────────────────────────────────────────────────────

  /// Sends pending previous-session reports, then the current session if dirty.
  /// Never throws. Concurrent calls collapse into one run + one re-run.
  Future<void> syncNow() async {
    if (!_started || !_enabled) return;
    if (_syncing) {
      _resync = true; // something changed mid-sync: run once more afterwards
      return;
    }
    if (!_isSignedIn()) return; // stay dirty until sign-in
    _syncing = true;
    _resync = false;
    try {
      while (_pending.isNotEmpty) {
        final p = _pending.first;
        await _transport(p.id, p.startupMs, p.meta);
        _pending.remove(p);
        _persist();
      }
      var guard = 0;
      while (_dirty && guard++ < 3) {
        final v = _version;
        await _transport(_sessionId, _startupMs, _currentMeta());
        if (_version == v) _dirty = false; // else: changed meanwhile, loop
      }
    } catch (e) {
      if (kDebugMode) debugPrint('🧭 SessionManager sync failed: ${e.runtimeType}');
    } finally {
      _syncing = false;
      _persist();
    }
    if (_resync && (_dirty || _pending.isNotEmpty)) {
      _resync = false;
      await syncNow();
    }
  }

  /// Call when the auth state changes (sign-in) so a waiting session is sent.
  void onAuthChanged() => unawaited(syncNow());

  // ── Internals ──────────────────────────────────────────────────────────

  Map<String, dynamic> _currentMeta() => {
    ..._deviceMeta(),
    if (_startupKind != null) 'startup_kind': _startupKind,
    if (_crashed) 'crashed': true,
    if (_crashed && _crashForeground) 'crash_foreground': true,
    if (_anr) 'anr': true,
  };

  void _resetFlags() {
    _crashed = false;
    _crashForeground = false;
    _anr = false;
    _startupMs = null;
    _startupKind = null;
  }

  void _enqueuePending(_Pending p) {
    _pending.add(p);
    while (_pending.length > maxPending) {
      _pending.removeAt(0);
    }
  }

  /// Reads the record left by the previous process. If that session was still
  /// in the FOREGROUND, the process died abnormally -> it crashed.
  Future<void> _recoverPreviousSession() async {
    try {
      final raw = await _store.read();
      if (raw == null || raw.isEmpty) return;
      final j = jsonDecode(raw);
      if (j is! Map) return;

      for (final item in (j['pending'] as List?) ?? const []) {
        final p = _Pending.fromJson(item);
        if (p != null) _enqueuePending(p);
      }

      final id = j['id'];
      if (id is! String || id.isEmpty) return;
      final wasForeground = j['fg'] == true;
      final crashed = j['crashed'] == true || wasForeground;
      final anr = j['anr'] == true;
      final dirty = j['dirty'] == true;
      if (!(crashed || anr || dirty)) return; // clean and already delivered

      final startupMs = j['startup_ms'];
      final kind = j['kind'];
      _enqueuePending(
        _Pending(id, startupMs is int ? startupMs : null, {
          ..._deviceMeta(),
          if (kind is String) 'startup_kind': kind,
          if (crashed) 'crashed': true,
          if (crashed && (j['crash_fg'] == true || wasForeground))
            'crash_foreground': true,
          if (anr) 'anr': true,
          'ended': true,
        }),
      );
    } catch (_) {
      // A corrupt record must never block startup.
    }
  }

  void _persist() {
    if (!_started) return;
    final json = jsonEncode({
      'id': _sessionId,
      'fg': _foreground,
      'crashed': _crashed,
      'crash_fg': _crashForeground,
      'anr': _anr,
      'startup_ms': _startupMs,
      'kind': _startupKind,
      'dirty': _dirty,
      'pending': _pending.map((p) => p.toJson()).toList(),
    });
    _writeChain = _writeChain
        .then((_) => _store.write(json))
        .catchError((Object _) {});
  }

  /// Completes when every queued write reached the store (tests / shutdown).
  Future<void> get persisted => _writeChain;

  // ── Defaults ───────────────────────────────────────────────────────────

  static Future<void> _rpcTransport(
    String sessionId,
    int? startupMs,
    Map<String, dynamic> meta,
  ) async {
    await SupabaseProvider.client.rpc(
      'session_heartbeat',
      params: {
        'p_session_id': sessionId,
        'p_startup_ms': startupMs,
        'p_device_meta': meta,
      },
    );
  }

  /// Non-identifying device description available WITHOUT a native plugin.
  /// `device_model` needs `device_info_plus` (native -> Type B); until then it
  /// is simply absent and the dashboard shows "unknown".
  static Map<String, dynamic> defaultDeviceMeta() {
    String? os;
    if (!kIsWeb) {
      try {
        final s = Platform.operatingSystemVersion;
        os = s.length > 64 ? s.substring(0, 64) : s;
      } catch (_) {}
    }
    return {
      'app_version': BuildInfo.appVersion,
      'build_number': BuildInfo.buildNumber,
      'platform': kIsWeb ? 'web' : defaultTargetPlatform.name.toLowerCase(),
      if (os != null) 'os_version': os,
    };
  }

  @visibleForTesting
  Future<void> debugWaitForIdle() async {
    await persisted;
    while (_syncing) {
      await Future<void>.delayed(Duration.zero);
    }
  }
}

/// Plug-in for `CompositeCrashReporter`: turns every FATAL report into
/// "this session crashed" without touching the Observability facade.
///
/// NOTE: like Crashlytics, a fatal here means `fatal: true` in the existing
/// pipeline (`FlutterError.onError` -> fatalCrash, uncaught zone errors) even if
/// the UI survived. That is the crash definition used by Crashlytics, so the
/// two dashboards stay comparable.
class SessionCrashReporter implements CrashReporter {
  SessionCrashReporter({SessionManager? manager}) : _manager = manager;

  static final SessionCrashReporter instance = SessionCrashReporter();

  final SessionManager? _manager;
  SessionManager get _m => _manager ?? SessionManager.instance;

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    required ErrorCategory category,
    String? reason,
    Iterable<Object> information = const [],
    bool fatal = false,
  }) async {
    if (fatal) _m.markCrashed();
  }

  @override
  Future<void> log(String message) async {}

  @override
  Future<void> setCustomKey(String key, Object value) async {}

  @override
  Future<void> setUserIdentifier(String identifier) async {}

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}
}
