import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../observability/realtime_diagnostics.dart';
import '../observability/telemetry_scrubber.dart';
import '../supabase/supabase_provider.dart';
import 'service_health_batcher.dart';
import 'service_health_sample.dart';

/// Default transport: the `record_service_telemetry_batch` RPC (migration 019).
/// The RPC is callable by `anon` and `authenticated`, takes no identifier and
/// never reads `auth.uid()`.
Future<void> supabaseServiceHealthSender(
  List<Map<String, dynamic>> samples,
) async {
  await SupabaseProvider.client.rpc(
    'record_service_telemetry_batch',
    params: <String, dynamic>{'p_samples': samples},
  );
}

/// Aggregates PASSIVE health signals from the subsystems the app already has
/// and hands one sample per service per minute to [ServiceHealthBatcher].
///
/// It is a pure observer:
///  * every `report*` method swallows its own errors (telemetry must never
///    break a feature),
///  * it adds no network call of its own besides the batched RPC,
///  * it never sees a user id, topic, URL, file name or payload.
///
/// Signal sources (wired by the small hooks in `flutter/integrations/`):
///  * Realtime  - [RealtimeDiagnostics] state transitions and channel errors,
///  * Cloudinary - upload success / failure and duration,
///  * LiveKit   - token acquisition result and connection drops,
///  * AI Gateway - result, latency and `degraded` (provider fallback),
///  * Hive      - init time, box resets (corruption recovery) and liveness.
class ServiceHealthCoordinator with WidgetsBindingObserver {
  ServiceHealthCoordinator({
    ServiceHealthBatcher? batcher,
    ServiceHealthSender? sender,
    DateTime Function()? clock,
  })  : _clock = clock ?? DateTime.now,
        _batcher = batcher ??
            ServiceHealthBatcher(
              sender: sender ?? supabaseServiceHealthSender,
            ) {
    _batcher.beforeFlush = drain;
  }

  static final ServiceHealthCoordinator instance = ServiceHealthCoordinator();

  final DateTime Function() _clock;
  final ServiceHealthBatcher _batcher;

  /// Kill switch. While `false` nothing is recorded or sent.
  bool enabled = true;

  /// Failures observed while the device is offline say nothing about the
  /// service, so they are not recorded. `null` = assume online.
  bool Function()? isOnline;

  /// Push-style alternative to [isOnline]: `ConnectivityCubit` calls this when
  /// it declares the device offline / restored (see integrations/).
  void setOnline(bool online) {
    isOnline = () => online;
  }

  final Map<HealthServiceKey, _Window> _windows = {};
  final Map<HealthServiceKey, bool? Function()> _liveness = {};
  bool _started = false;

  /// Errors the service answered on purpose (quota, validation, ...): the
  /// service is up, so they count as healthy calls.
  static const Set<String> _expectedAiReasons = {
    'user_quota_exceeded',
    'global_quota_exceeded',
    'rate_limited',
    'unauthorized',
    'invalid_request',
  };

  /// `DisconnectReason.name` values that are NOT a connection drop.
  static const Set<String> _benignLiveKitReasons = {
    'clientinitiated',
    'participantremoved',
    'roomdeleted',
    'roomclosed',
    'userrejected',
    'userunavailable',
    'duplicateidentity',
  };

  ServiceHealthBatcher get batcher => _batcher;
  bool get isStarted => _started;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Starts the 60 s flush timer, the app-pause flush and the Realtime hook.
  /// Idempotent. Call once after Observability / Supabase are initialised.
  ///
  /// [sampleRate] (0..1) is the chance that THIS app session reports at all.
  /// Leave it at 1.0 for a small fleet; lower it (for example 0.2) when many
  /// thousands of sessions run concurrently, so telemetry volume stays flat
  /// while the aggregated error rate stays statistically sound.
  void start({
    bool Function()? isOnline,
    double sampleRate = 1.0,
    math.Random? random,
  }) {
    if (_started) return;
    _started = true;
    if (sampleRate < 1.0 &&
        (random ?? math.Random()).nextDouble() >= sampleRate) {
      enabled = false; // this session is not part of the sample
      return;
    }
    if (isOnline != null) {
      this.isOnline = isOnline;
    }
    _batcher.isOnline = () => this.isOnline?.call() ?? true;
    attachRealtimeDiagnostics();
    registerLivenessCheck(
      HealthServiceKey.supabaseRealtime,
      _realtimeLiveness,
    );
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}
    _batcher.start();
  }

  void stop() {
    if (!_started) return;
    _started = false;
    detachRealtimeDiagnostics();
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
    _batcher.stop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(flushNow());
    }
  }

  /// Drains the aggregation windows and sends the queue.
  Future<void> flushNow() => _batcher.flush();

  void attachRealtimeDiagnostics() {
    RealtimeDiagnostics.instance.healthListener = reportRealtimeEvent;
  }

  void detachRealtimeDiagnostics() {
    if (RealtimeDiagnostics.instance.healthListener == reportRealtimeEvent) {
      RealtimeDiagnostics.instance.healthListener = null;
    }
  }

  /// Registers a cheap "is it alive right now?" check used when a service had
  /// no traffic during a window, so quiet-but-healthy services (Hive, an idle
  /// Realtime connection) still produce enough samples for the 5-sample rule.
  /// The check returns `null` when it has nothing to say (e.g. not initialised).
  void registerLivenessCheck(HealthServiceKey key, bool? Function() check) {
    _liveness[key] = check;
  }

  void unregisterLivenessCheck(HealthServiceKey key) {
    _liveness.remove(key);
  }

  bool? _realtimeLiveness() {
    final active = RealtimeDiagnostics.instance.active;
    if (active.isEmpty) return null; // signed out / nothing open
    return active.any((c) => c.phase == ChannelPhase.subscribed);
  }

  // ---------------------------------------------------------------------------
  // Generic recording
  // ---------------------------------------------------------------------------

  /// Records one call. [degraded]: `true`/`false` overwrite the window flag,
  /// `null` leaves it unchanged.
  void reportCall(
    HealthServiceKey service, {
    required bool success,
    Duration? latency,
    String? reasonCode,
    Object? error,
    String? provider,
    bool? degraded,
  }) {
    if (!enabled) return;
    try {
      if (!success && isOnline?.call() == false) return;
      final w = _windows.putIfAbsent(service, () => _Window(_clock()));
      w.add(
        success: success,
        latencyMs: latency?.inMilliseconds,
        reasonCode: reasonCode,
        provider: provider,
        degraded: degraded,
        errorText: success || error == null
            ? null
            : TelemetryScrubber.scrubLine(error.toString(), maxLength: 160),
      );
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Domain helpers (the only methods the integrations call)
  // ---------------------------------------------------------------------------

  /// Do NOT call for a user-cancelled upload or a missing local file: neither
  /// says anything about Cloudinary.
  void reportCloudinaryUpload({
    required bool success,
    required Duration duration,
    Object? error,
  }) {
    reportCall(
      HealthServiceKey.cloudinary,
      success: success,
      latency: duration,
      reasonCode: success ? null : 'upload_failed',
      error: error,
    );
  }

  void reportLiveKitToken({
    required bool success,
    required Duration duration,
    Object? error,
  }) {
    reportCall(
      HealthServiceKey.livekit,
      success: success,
      latency: duration,
      reasonCode: success ? null : 'token_failed',
      error: error,
    );
  }

  /// Call from the call views when the Room disconnects. [reasonName] is the
  /// `DisconnectReason.name`; user-initiated endings are ignored.
  void reportLiveKitConnectionEnded(String? reasonName) {
    final reason = reasonName?.toLowerCase();
    if (reason != null && _benignLiveKitReasons.contains(reason)) return;
    reportCall(
      HealthServiceKey.livekit,
      success: false,
      reasonCode: 'connection_drop',
      error: reasonName == null ? 'connection dropped' : 'dropped: $reasonName',
    );
  }

  /// [expectedFailure]: the gateway answered on purpose with an error such as
  /// HTTP 429 / 401. The service is up, so it is recorded as healthy.
  void reportAiGateway({
    required bool success,
    required Duration duration,
    bool degraded = false,
    String? provider,
    String? reason,
    bool expectedFailure = false,
    Object? error,
  }) {
    final expected = expectedFailure ||
        (reason != null &&
            (_expectedAiReasons.contains(reason) ||
                reason.contains('quota')));
    final ok = success || expected;
    reportCall(
      HealthServiceKey.aiGateway,
      success: ok,
      latency: duration,
      reasonCode: ok ? null : (reason ?? 'gateway_error'),
      provider: provider,
      degraded: degraded,
      error: ok ? null : (error ?? reason),
    );
  }

  void reportHiveInit({required bool success, required Duration duration, Object? error}) {
    reportCall(
      HealthServiceKey.hiveCache,
      success: success,
      latency: duration,
      reasonCode: success ? null : 'init_failed',
      error: error,
    );
  }

  /// A Hive box failed to open and was deleted + recreated (corruption
  /// recovery). The cache works again, but is degraded until the next window
  /// without a reset. [boxName] is an app constant, never user data.
  void reportHiveBoxReset(String boxName) {
    reportCall(
      HealthServiceKey.hiveCache,
      success: true,
      reasonCode: 'box_reset',
      degraded: true,
      error: null,
    );
    _windows[HealthServiceKey.hiveCache]?.lastError = 'box recreated: $boxName';
  }

  void reportRealtimeEvent(RealtimeHealthEventType type) {
    if (!enabled) return;
    try {
      switch (type) {
        case RealtimeHealthEventType.subscribed:
          reportCall(HealthServiceKey.supabaseRealtime, success: true);
        case RealtimeHealthEventType.reconnected:
          reportCall(HealthServiceKey.supabaseRealtime, success: true);
          _windows
              .putIfAbsent(
                HealthServiceKey.supabaseRealtime,
                () => _Window(_clock()),
              )
              .reconnects++;
        case RealtimeHealthEventType.errored:
          reportCall(
            HealthServiceKey.supabaseRealtime,
            success: false,
            reasonCode: 'channel_error',
            error: 'realtime channel error',
          );
      }
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Aggregation
  // ---------------------------------------------------------------------------

  /// Turns every non-empty window into a [ServiceHealthSample], queues it and
  /// starts a fresh window. Called by the batcher before each flush.
  void drain() {
    if (!enabled) {
      _windows.clear();
      return;
    }
    final now = _clock();

    // Quiet services: ask their liveness check for one data point.
    _liveness.forEach((key, check) {
      if ((_windows[key]?.samples ?? 0) > 0) return;
      try {
        final alive = check();
        if (alive == null) return;
        if (!alive && isOnline?.call() == false) return;
        final w = _windows.putIfAbsent(key, () => _Window(now));
        w.add(
          success: alive,
          reasonCode: alive ? null : 'liveness_failed',
          errorText: alive ? null : 'liveness check failed',
        );
      } catch (_) {}
    });

    final finished = <HealthServiceKey, _Window>{
      for (final e in _windows.entries)
        if (e.value.samples > 0) e.key: e.value,
    };
    _windows.clear();

    for (final entry in finished.entries) {
      final key = entry.key;
      final w = entry.value;
      final elapsedSeconds = math.max(now.difference(w.start).inSeconds, 30);
      _batcher.add(
        ServiceHealthSample(
          service: key,
          sampleCount: w.samples,
          errorCount: w.errors,
          observedAt: now.toUtc(),
          latencyP95Ms: w.p95(),
          reconnectsPerMin: key == HealthServiceKey.supabaseRealtime
              ? w.reconnects * 60 / elapsedSeconds
              : null,
          degraded: w.degraded,
          reasonCode: w.reasonCode,
          provider: w.provider,
          lastError: w.lastError,
        ),
      );
    }
  }

  /// Test helper: windows that have not been drained yet.
  @visibleForTesting
  int get openWindowCount => _windows.length;
}

/// Mutable accumulator for one service during one window.
class _Window {
  _Window(this.start);

  static const int _maxLatencies = 256;

  final DateTime start;
  int samples = 0;
  int errors = 0;
  int reconnects = 0;
  bool? degraded;
  String? reasonCode;
  String? provider;
  String? lastError;
  final List<int> _latencies = <int>[];

  void add({
    required bool success,
    int? latencyMs,
    String? reasonCode,
    String? provider,
    bool? degraded,
    String? errorText,
  }) {
    samples++;
    if (!success) {
      errors++;
      if (reasonCode != null) this.reasonCode = reasonCode;
      if (errorText != null) lastError = errorText;
    } else if (reasonCode != null && this.reasonCode == null) {
      this.reasonCode = reasonCode;
    }
    if (provider != null) this.provider = provider;
    if (degraded != null) this.degraded = degraded;
    if (latencyMs != null && latencyMs >= 0) {
      if (_latencies.length >= _maxLatencies) _latencies.removeAt(0);
      _latencies.add(latencyMs);
    }
  }

  /// Nearest-rank 95th percentile; `null` without latency data.
  int? p95() {
    if (_latencies.isEmpty) return null;
    final sorted = List<int>.of(_latencies)..sort();
    final idx = (sorted.length * 0.95).ceil() - 1;
    return sorted[idx.clamp(0, sorted.length - 1)];
  }
}
