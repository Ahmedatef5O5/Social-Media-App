import 'dart:async';

import 'package:flutter/foundation.dart';

import '../observability/build_info.dart';
import '../observability/observability.dart';
import '../supabase/supabase_provider.dart';
import 'performance_metric.dart';
import 'performance_queue.dart';
import 'session_manager.dart';

/// Sends one batch to the backend. Default: `rpc('log_performance_batch')`.
/// Returns the RPC payload (`{ok, accepted, rejected, dropped}`).
typedef PerformanceTransport =
    Future<Object?> Function(List<Map<String, dynamic>> metrics);

typedef PerfFlushCanceller = void Function();

/// Schedules [callback] after [delay]; returns a canceller. Injectable so tests
/// drive flushing without real timers.
typedef PerfFlushScheduler =
    PerfFlushCanceller Function(Duration delay, void Function() callback);

/// Singleton facade for recording performance spans:
///
/// ```dart
/// final trace = PerformanceTracker.instance.startTrace('cloudinary:image', MetricCategory.upload);
/// try { await upload(); trace.stop(); }
/// catch (e) { trace.stop(success: false, errorCode: MetricErrorCodes.network); }
/// ```
///
/// CONTRACT (same philosophy as `IncidentReporter`)
///  * never blocks the UI isolate, never throws, never reports its OWN failures
///    through `Observability` (that would feed back into itself);
///  * samples are buffered (max 100, see [PerformanceQueue]) and flushed every
///    30 s, as soon as 20 are waiting, and when the app goes to background
///    ([flush]);
///  * while signed out or offline samples stay queued; failed batches are
///    re-queued and retried with exponential back-off (30 s -> 5 min);
///  * a failed or slow operation leaves a PII-free breadcrumb in
///    `Observability`, so a later crash report shows what the app was doing.
///
/// Pure Dart: Shorebird Type A.
class PerformanceTracker {
  PerformanceTracker({
    PerformanceTransport? transport,
    String Function()? sessionIdProvider,
    String Function()? appVersionProvider,
    bool Function()? isSignedIn,
    DateTime Function()? now,
    PerfFlushScheduler? scheduler,
    void Function(String message)? onBreadcrumb,
    PerformanceQueue? queue,
    bool? enabled,
  }) : _transport = transport ?? _rpcTransport,
       _sessionIdProvider =
           sessionIdProvider ?? (() => SessionManager.instance.sessionId),
       _appVersionProvider = appVersionProvider ?? (() => BuildInfo.appVersion),
       _isSignedIn = isSignedIn ?? (() => SupabaseProvider.isAuthenticated),
       _now = now ?? DateTime.now,
       _scheduler = scheduler ?? _timerScheduler,
       _onBreadcrumb = onBreadcrumb ?? _obsBreadcrumb,
       queue = queue ?? PerformanceQueue(),
       _enabled = enabled ?? _defaultEnabled;

  /// Process-wide instance used by the interceptors and integrations.
  static final PerformanceTracker instance = PerformanceTracker();

  static const String rpcName = 'log_performance_batch';

  /// Operations that must never be measured (they ARE the telemetry transport,
  /// measuring them would create an infinite feedback loop).
  static const Set<String> selfRpcNames = {
    rpcName,
    'session_heartbeat',
    'incident_report_batch',
  };

  static const Duration flushInterval = Duration(seconds: 30);
  static const Duration maxBackoff = Duration(minutes: 5);
  static const int flushThreshold = 20;

  /// Server-side cap per call (`log_performance_batch`: 50).
  static const int maxBatchSize = 50;

  /// An operation slower than this leaves a "slow" breadcrumb.
  static const Map<MetricCategory, Duration> slowAfter = {
    MetricCategory.apiRpc: Duration(seconds: 3),
    MetricCategory.upload: Duration(seconds: 30),
    MetricCategory.callConnect: Duration(seconds: 10),
    MetricCategory.messageDelivery: Duration(seconds: 3),
  };

  /// Off in debug builds (like crash collection) unless
  /// `--dart-define=PERF_TELEMETRY=true`.
  static final bool _defaultEnabled =
      !kDebugMode || const bool.fromEnvironment('PERF_TELEMETRY');

  final PerformanceTransport _transport;
  final String Function() _sessionIdProvider;
  final String Function() _appVersionProvider;
  final bool Function() _isSignedIn;
  final DateTime Function() _now;
  final PerfFlushScheduler _scheduler;
  final void Function(String message) _onBreadcrumb;
  final PerformanceQueue queue;

  bool _enabled;
  PerfFlushCanceller? _cancelScheduled;
  Future<void>? _inFlight;
  bool _flushing = false;
  int _consecutiveFailures = 0;

  bool get isEnabled => _enabled;

  /// Back-off currently applied to the next scheduled flush.
  Duration get currentBackoff => _backoffFor(_consecutiveFailures);

  void setEnabled(bool enabled) {
    _enabled = enabled;
    if (!enabled) {
      _cancelScheduled?.call();
      _cancelScheduled = null;
      queue.clear();
    }
  }

  // ── Recording ──────────────────────────────────────────────────────────

  /// Starts a span. Call [PerformanceTrace.stop] exactly once.
  PerformanceTrace startTrace(String name, MetricCategory category) =>
      PerformanceTrace._(this, name, category, _now());

  /// Runs [body] and records its duration. Exceptions are recorded as failures
  /// (`error_code` from [errorCodeFor]) and rethrown untouched.
  Future<T> traceAsync<T>(
    String name,
    MetricCategory category,
    Future<T> Function() body, {
    String Function(Object error)? errorCodeFor,
  }) async {
    final trace = startTrace(name, category);
    try {
      final result = await body();
      trace.stop();
      return result;
    } catch (e) {
      trace.stop(
        success: false,
        errorCode: (errorCodeFor ?? defaultErrorCodeFor)(e),
      );
      rethrow;
    }
  }

  /// Maps an exception to a short code without ever including its message.
  static String defaultErrorCodeFor(Object error) {
    if (error is TimeoutException) return MetricErrorCodes.timeout;
    return MetricErrorCodes.unknown;
  }

  /// Records a finished operation. Safe to call from anywhere, never throws.
  void record({
    required MetricCategory category,
    required String operation,
    required Duration duration,
    required bool success,
    String? errorCode,
  }) {
    if (!_enabled) return;
    try {
      if (errorCode == MetricErrorCodes.userCancelled) return; // not a failure
      if (selfRpcNames.contains(operation.replaceFirst('rpc:', ''))) return;

      final metric = PerformanceMetric(
        category: category,
        operationName: operation,
        durationMs: duration.inMilliseconds,
        isSuccess: success,
        errorCode: errorCode,
        recordedAt: _now(),
        sessionId: _sessionIdProvider(),
        appVersion: _appVersionProvider(),
      );
      queue.add(metric);

      if (metric.isFailure) {
        _onBreadcrumb(
          'perf ${category.wire}:${metric.operationName} failed '
          '${metric.errorCode ?? '-'} after ${metric.durationMs}ms',
        );
      } else if (duration > (slowAfter[category] ?? const Duration(seconds: 5))) {
        _onBreadcrumb(
          'perf ${category.wire}:${metric.operationName} slow '
          '${metric.durationMs}ms',
        );
      }

      if (queue.length >= flushThreshold) {
        unawaited(flush());
      } else {
        _scheduleFlush(flushInterval);
      }
    } catch (e) {
      _debug('record failed: $e');
    }
  }

  // ── Delivery ───────────────────────────────────────────────────────────

  /// Sends everything buffered, in batches of at most [maxBatchSize]. Always
  /// completes normally. Concurrent calls share one run. Call it when the app
  /// goes to background.
  Future<void> flush() {
    // `_flushing` is cleared INSIDE `_drain` (synchronously with completion), so
    // a call made right after a finished run always starts a fresh one instead
    // of joining a run that is already over.
    if (_flushing) return _inFlight!;
    _flushing = true;
    return _inFlight = _drain();
  }

  Future<void> _drain() async {
    try {
      _cancelScheduled?.call();
      _cancelScheduled = null;
      if (!_enabled || queue.isEmpty) return;

      if (!_isSignedIn()) {
        _scheduleFlush(flushInterval); // keep samples, try again later
        return;
      }

      while (queue.isNotEmpty) {
        final batch = queue.takeBatch(maxBatchSize);

        // Samples recorded before the session existed (bootstrap) get the
        // current session id now. If there is still none (background isolate,
        // session disabled) the server could only reject them: drop.
        final sid = _sessionIdProvider();
        final sendable = <PerformanceMetric>[
          for (final m in batch)
            if (m.sessionId.isNotEmpty)
              m
            else if (sid.isNotEmpty)
              m.withSessionId(sid),
        ];
        if (sendable.isEmpty) continue;

        try {
          final result = await _transport(
            sendable.map((m) => m.toJson()).toList(growable: false),
          );
          if (result is Map && result['ok'] == false) {
            // Server rejected the whole batch (validation). Retrying the same
            // payload can never succeed: drop it.
            _debug('batch rejected by server: ${result['code']}');
          }
          _consecutiveFailures = 0;
        } catch (e) {
          queue.requeueFront(sendable);
          _consecutiveFailures++;
          _debug('flush failed ($_consecutiveFailures): ${e.runtimeType}');
          _scheduleFlush(_backoffFor(_consecutiveFailures));
          return;
        }
      }
    } finally {
      _flushing = false;
    }
  }

  void _scheduleFlush(Duration delay) {
    if (_cancelScheduled != null || !_enabled) return;
    _cancelScheduled = _scheduler(delay, () {
      _cancelScheduled = null;
      unawaited(flush());
    });
  }

  static Duration _backoffFor(int failures) {
    if (failures <= 0) return flushInterval;
    final seconds = flushInterval.inSeconds * (1 << (failures > 6 ? 6 : failures));
    final d = Duration(seconds: seconds);
    return d > maxBackoff ? maxBackoff : d;
  }

  // ── Defaults ───────────────────────────────────────────────────────────

  static Future<Object?> _rpcTransport(List<Map<String, dynamic>> metrics) async {
    return await SupabaseProvider.client.rpc(
      rpcName,
      params: {'p_metrics': metrics},
    );
  }

  static PerfFlushCanceller _timerScheduler(
    Duration delay,
    void Function() callback,
  ) {
    final timer = Timer(delay, callback);
    return timer.cancel;
  }

  static void _obsBreadcrumb(String message) {
    unawaited(Observability.instance.breadcrumb(message, feature: 'performance'));
  }

  static void _debug(String message) {
    if (kDebugMode) debugPrint('⏱️ PerformanceTracker: $message');
  }
}

/// A running span returned by [PerformanceTracker.startTrace].
class PerformanceTrace {
  PerformanceTrace._(this._tracker, this.name, this.category, this._startedAt);

  final PerformanceTracker _tracker;
  final String name;
  final MetricCategory category;
  final DateTime _startedAt;
  bool _finished = false;

  bool get isFinished => _finished;

  /// Finishes the span. Only the first call counts; later calls are ignored,
  /// so `finally` + `catch` can both call it safely.
  void stop({bool success = true, String? errorCode}) {
    if (_finished) return;
    _finished = true;
    _tracker.record(
      category: category,
      operation: name,
      duration: _tracker._now().difference(_startedAt),
      success: success,
      errorCode: errorCode ?? (success ? null : MetricErrorCodes.unknown),
    );
  }

  /// Discards the span without recording anything (user cancelled, screen
  /// closed before a result existed).
  void cancel() => _finished = true;
}
