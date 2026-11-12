import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_media_app/core/observability/app_logger.dart';
import 'package:social_media_app/core/observability/build_info.dart';
import 'package:social_media_app/core/supabase/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'analytics_event.dart';
import 'analytics_queue.dart';
import 'analytics_session_manager.dart';

export 'analytics_event.dart' show AnalyticsEvents, AnalyticsFeatures;

/// Product-analytics facade used by the rest of the app.
///
/// Contract for callers
///  * Every method is fire-and-forget safe: it NEVER throws and never blocks
///    the UI for more than a local storage write. Wrap calls in `unawaited(...)`.
///  * Only the allow-listed events/properties of [AnalyticsEvents] exist. There
///    is no API for free text, names, emails or message/post content.
///  * Until [initialize] completes, `AnalyticsClient.instance` is a no-op, so
///    call sites never need a null check.
abstract class AnalyticsClient {
  const AnalyticsClient();

  static AnalyticsClient _instance = const NoopAnalyticsClient();

  /// The active client ([NoopAnalyticsClient] before [initialize]).
  static AnalyticsClient get instance => _instance;

  /// Replaces the active client (tests / alternative back-ends).
  @visibleForTesting
  static set instance(AnalyticsClient client) => _instance = client;

  /// Wires storage, queue, lifecycle hooks and the Supabase sender. Safe to
  /// call more than once. Call it from `initializeCoreServices()` after Supabase
  /// is ready; it returns quickly and never throws.
  static Future<AnalyticsClient> initialize({
    AnalyticsConfig config = const AnalyticsConfig(),
  }) async {
    final current = _instance;
    if (current is DefaultAnalyticsClient) return current;
    try {
      final prefs = await SharedPreferences.getInstance();
      final storage = SharedPreferencesAnalyticsStorage(prefs);
      final sender = SupabaseAnalyticsSender(
        authUserId: () => SupabaseProvider.idOrNull,
      );
      final client = DefaultAnalyticsClient(
        storage: storage,
        sender: sender.call,
        config: config,
        userIdProvider: () => SupabaseProvider.idOrNull,
      );
      await client.start();
      _instance = client;
      return client;
    } catch (e, s) {
      const AppLogger('analytics').error(e, s, operation: 'initialize');
      return _instance;
    }
  }

  /// Records [eventName]. Unknown names / properties are dropped.
  Future<void> track(
    String eventName, {
    Map<String, Object?> properties = const <String, Object?>{},
  });

  /// Records [eventName] at most once per [onceKey] (normally the user id),
  /// across restarts AND devices: the event id is derived from the pair, so the
  /// backend's primary key ignores a repeat. Use for first_* / lifecycle events.
  Future<void> trackOnce(
    String eventName, {
    required String onceKey,
    Map<String, Object?> properties = const <String, Object?>{},
  });

  /// Records `feature_used` for [featureName] (one of [AnalyticsFeatures]) at most
  /// ONCE per feature per app session, so calling it from `initState` / `build`
  /// paths cannot flood the queue. Unknown feature names are ignored.
  Future<void> trackFeatureUsed(String featureName);

  /// Links subsequent events to [userId]; `null` on sign-out. Events already
  /// queued keep their original attribution; any event whose user no longer
  /// matches the signed-in user is sent anonymously (never as someone else).
  void setUserId(String? userId);

  /// Sends whatever is queued (honours batching; ignores the back-off window).
  Future<void> flush();

  /// Privacy switch. `false` stops collection, empties the queue and rotates
  /// the anonymous id; the choice is persisted.
  Future<void> setEnabled(bool enabled);

  bool get isEnabled;

  Future<void> dispose();
}

/// Default before initialisation and in tests that do not care about analytics.
class NoopAnalyticsClient extends AnalyticsClient {
  const NoopAnalyticsClient();

  @override
  Future<void> track(
    String eventName, {
    Map<String, Object?> properties = const <String, Object?>{},
  }) async {}

  @override
  Future<void> trackOnce(
    String eventName, {
    required String onceKey,
    Map<String, Object?> properties = const <String, Object?>{},
  }) async {}

  @override
  Future<void> trackFeatureUsed(String featureName) async {}

  @override
  void setUserId(String? userId) {}

  @override
  Future<void> flush() async {}

  @override
  Future<void> setEnabled(bool enabled) async {}

  @override
  bool get isEnabled => false;

  @override
  Future<void> dispose() async {}
}

class AnalyticsConfig {
  const AnalyticsConfig({
    this.maxBatchSize = 20,
    this.maxQueueSize = 200,
    this.flushInterval = const Duration(seconds: 30),
    this.sessionGrace = const Duration(seconds: 30),
    this.appVersion,
  });

  final int maxBatchSize;
  final int maxQueueSize;
  final Duration flushInterval;
  final Duration sessionGrace;

  /// Defaults to `BuildInfo.releaseVersion` (for example `1.0.0+2`).
  final String? appVersion;
}

/// Real implementation. All collaborators are injectable so the whole pipeline
/// can be exercised in unit tests without Firebase, Supabase or a device.
class DefaultAnalyticsClient extends AnalyticsClient {
  DefaultAnalyticsClient({
    required AnalyticsStorage storage,
    required AnalyticsSender sender,
    AnalyticsConfig config = const AnalyticsConfig(),
    String? Function()? userIdProvider,
    AnalyticsScheduler scheduler = const SystemAnalyticsScheduler(),
    DateTime Function()? now,
    String? platform,
    bool observeLifecycle = true,
  }) : _storage = storage,
       _config = config,
       _userIdProvider = userIdProvider,
       _now = now ?? DateTime.now,
       _platform = platform ?? AnalyticsPlatform.detect(),
       _observeLifecycle = observeLifecycle,
       _sessions = AnalyticsSessionManager(
         storage: storage,
         now: now,
         inactivityGrace: config.sessionGrace,
       ),
       _queue = AnalyticsQueue(
         storage: storage,
         sender: sender,
         scheduler: scheduler,
         now: now,
         maxBatchSize: config.maxBatchSize,
         maxQueueSize: config.maxQueueSize,
         flushInterval: config.flushInterval,
       );

  static const String _enabledKey = 'analytics.enabled.v1';
  static const String _onceKey = 'analytics.once.v1';
  static const int _maxOnceKeys = 500;
  static const AppLogger _log = AppLogger('analytics');

  final AnalyticsStorage _storage;
  final AnalyticsConfig _config;
  final String? Function()? _userIdProvider;
  final DateTime Function() _now;
  final String _platform;
  final bool _observeLifecycle;
  final AnalyticsSessionManager _sessions;
  final AnalyticsQueue _queue;

  final List<String> _onceFired = <String>[];
  final Set<String> _featuresThisSession = <String>{};
  String? _featureSession;
  _LifecycleObserver? _observer;
  String? _userId;
  bool _enabled = true;
  bool _started = false;

  AnalyticsQueue get queue => _queue;
  AnalyticsSessionManager get sessions => _sessions;

  @override
  bool get isEnabled => _enabled;

  /// Loads persisted state and begins collecting. Never throws.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      _enabled = (await _storage.read(_enabledKey)) != 'false';
      await _sessions.init();
      await _queue.restore();
      await _loadOnce();
      _userId = _userIdProvider?.call();
      if (_observeLifecycle) {
        _observer = _LifecycleObserver(this);
        WidgetsBinding.instance.addObserver(_observer!);
      }
      if (_enabled) {
        _queue.start();
        await handleForeground(); // the app is already in the foreground
      }
    } catch (e, s) {
      _log.error(e, s, operation: 'start');
    }
  }

  /// Foreground hook (also driven by the lifecycle observer).
  Future<void> handleForeground() async {
    if (!_enabled) return;
    try {
      if (_sessions.onForeground()) {
        await track(AnalyticsEvents.appSessionStarted);
      }
    } catch (e, s) {
      _log.error(e, s, operation: 'foreground');
    }
  }

  /// Background hook: end the session clock and push what we have.
  Future<void> handleBackground() async {
    try {
      _sessions.onBackground();
      if (_enabled) await _queue.flush(force: true);
    } catch (e, s) {
      _log.error(e, s, operation: 'background');
    }
  }

  @override
  Future<void> track(
    String eventName, {
    Map<String, Object?> properties = const <String, Object?>{},
  }) => _record(eventName, properties, eventId: null);

  @override
  Future<void> trackOnce(
    String eventName, {
    required String onceKey,
    Map<String, Object?> properties = const <String, Object?>{},
  }) async {
    if (!_enabled || onceKey.isEmpty) return;
    final key = '$eventName:$onceKey';
    if (_onceFired.contains(key)) return;
    _onceFired.add(key);
    if (_onceFired.length > _maxOnceKeys) {
      _onceFired.removeRange(0, _onceFired.length - _maxOnceKeys);
    }
    unawaited(_saveOnce());
    await _record(
      eventName,
      properties,
      eventId: AnalyticsEvent.deterministicId(key),
    );
  }

  Future<void> _record(
    String eventName,
    Map<String, Object?> properties, {
    required String? eventId,
  }) async {
    if (!_enabled || !_sessions.isInitialized) return;
    try {
      // A first event can race the foreground hook; make sure a session exists.
      if (_sessions.sessionId == null) _sessions.onForeground();
      final event = AnalyticsEvent.create(
        name: eventName,
        anonymousId: _sessions.anonymousId,
        sessionId: _sessions.sessionId!,
        userId: _userId ?? _userIdProvider?.call(),
        properties: properties,
        timestamp: _now(),
        appVersion: _config.appVersion ?? BuildInfo.releaseVersion,
        platform: _platform,
        eventId: eventId,
      );
      await _queue.enqueue(event);
    } catch (e, s) {
      _log.error(e, s, operation: 'track:$eventName');
    }
  }

  @override
  Future<void> trackFeatureUsed(String featureName) async {
    if (!_enabled || !_sessions.isInitialized) return;
    if (!AnalyticsFeatures.all.contains(featureName)) return;
    if (_sessions.sessionId == null) _sessions.onForeground();
    final session = _sessions.sessionId;
    if (_featureSession != session) {
      _featureSession = session;
      _featuresThisSession.clear();
    }
    if (!_featuresThisSession.add(featureName)) return;
    await track(
      AnalyticsEvents.featureUsed,
      properties: <String, Object?>{'feature_name': featureName},
    );
  }

  @override
  void setUserId(String? userId) {
    _userId = (userId == null || userId.isEmpty) ? null : userId;
  }

  @override
  Future<void> flush() async {
    try {
      await _queue.flush(force: true);
    } catch (e, s) {
      _log.error(e, s, operation: 'flush');
    }
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    if (enabled == _enabled) return;
    _enabled = enabled;
    try {
      await _storage.write(_enabledKey, enabled ? 'true' : 'false');
      if (enabled) {
        await _sessions.resetIdentity();
        _queue.start();
        await handleForeground();
      } else {
        _queue.stop();
        await _queue.clear();
        _onceFired.clear();
        await _storage.delete(_onceKey);
        await _sessions.resetIdentity();
      }
    } catch (e, s) {
      _log.error(e, s, operation: 'setEnabled');
    }
  }

  Future<void> _loadOnce() async {
    try {
      final raw = await _storage.read(_onceKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _onceFired
          ..clear()
          ..addAll(decoded.whereType<String>());
      }
    } catch (_) {
      _onceFired.clear();
    }
  }

  Future<void> _saveOnce() async {
    try {
      await _storage.write(_onceKey, jsonEncode(_onceFired));
    } catch (_) {}
  }

  @override
  Future<void> dispose() async {
    final observer = _observer;
    if (observer != null) {
      WidgetsBinding.instance.removeObserver(observer);
      _observer = null;
    }
    _queue.stop();
  }
}

class _LifecycleObserver with WidgetsBindingObserver {
  _LifecycleObserver(this._client);
  final DefaultAnalyticsClient _client;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_client.handleForeground());
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        unawaited(_client.handleBackground());
      case AppLifecycleState.inactive:
        break; // transient (dialogs, app switcher peek): not a background
    }
  }
}

/// `SharedPreferences`-backed [AnalyticsStorage].
class SharedPreferencesAnalyticsStorage implements AnalyticsStorage {
  const SharedPreferencesAnalyticsStorage(this._prefs);
  final SharedPreferences _prefs;

  @override
  Future<String?> read(String key) async => _prefs.getString(key);

  @override
  Future<void> write(String key, String value) async {
    await _prefs.setString(key, value);
  }

  @override
  Future<void> delete(String key) async {
    await _prefs.remove(key);
  }
}

/// Delivers batches through the `log_analytics_events` RPC.
///
/// Identity safety: the RPC rejects any event whose `user_id` differs from the
/// caller's `auth.uid()`. Events queued while user A was signed in but flushed
/// after sign-out (or after user B signed in) would be rejected forever, so
/// their `user_id` is stripped here and they are recorded anonymously instead.
class SupabaseAnalyticsSender {
  SupabaseAnalyticsSender({SupabaseClient? client, this.authUserId})
    : _client = client;

  final String? Function()? authUserId;
  final SupabaseClient? _client;

  SupabaseClient get _supabase => _client ?? SupabaseProvider.client;

  /// Strips `user_id` from events that do not belong to [currentUser] so the
  /// server records them anonymously instead of rejecting them.
  @visibleForTesting
  static List<Map<String, dynamic>> prepareBatch(
    List<Map<String, dynamic>> batch,
    String? currentUser,
  ) => batch
      .map(
        (e) =>
            e['user_id'] != null && e['user_id'] != currentUser
                ? <String, dynamic>{...e, 'user_id': null}
                : e,
      )
      .toList(growable: false);

  Future<AnalyticsSendOutcome> call(List<Map<String, dynamic>> batch) async {
    final prepared = prepareBatch(batch, authUserId?.call());
    try {
      await _supabase.rpc(
        'log_analytics_events',
        params: <String, dynamic>{'p_events': prepared},
      );
      return AnalyticsSendOutcome.success;
    } on PostgrestException catch (e) {
      // 22023 = invalid payload / batch too large: retrying can never help.
      if (e.code == '22023' || e.code == 'PGRST102') {
        return AnalyticsSendOutcome.drop;
      }
      return AnalyticsSendOutcome.retry;
    } catch (_) {
      return AnalyticsSendOutcome.retry; // offline, timeout, TLS, ...
    }
  }
}
