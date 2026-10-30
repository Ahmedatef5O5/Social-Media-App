import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../services/active_screen_tracker.dart';
import '../supabase/supabase_provider.dart';
import 'build_info.dart';
import 'crash_reporter.dart';
import 'error_category.dart';
import 'fingerprint_throttle.dart';
import 'overflow_filter.dart';
import 'telemetry_scrubber.dart';

/// Sends one batch of reports to the backend. The default implementation calls
/// `rpc('incident_report_batch', params: {'p_reports': reports})`.
typedef IncidentTransport =
    Future<Object?> Function(List<Map<String, dynamic>> reports);

typedef FlushCanceller = void Function();

/// Schedules [callback] after [delay]; returns a function that cancels it.
/// Injectable so tests can drive the 30 s flush without real timers.
typedef FlushScheduler =
    FlushCanceller Function(Duration delay, void Function() callback);

/// Ships incidents to the Operations Control Platform
/// (`public.incident_report_batch`, migration 014).
///
/// CONTRACT WITH THE SERVER (014_operations_foundation.sql)
/// ─────────────────────────────────────────────────────────
/// * Callable by `authenticated` only. While signed out, reports stay in the
///   buffer and are delivered after sign-in.
/// * At most 20 items and 256 KiB per call -> [maxBatchSize]; every field is
///   length-bounded client-side as well.
/// * Server groups by `fingerprint`; categories are
///   crash|error|network|auth|realtime|call|upload|performance|other.
///   (`layout_overflow` is not in that list yet, so overflows go out as
///   `other` with `context.kind = 'layout_overflow'`.)
/// * The server rate-limits per user (60/min, 5 per incident per hour) and
///   silently drops the excess; that is why this class also throttles.
///
/// HARD RULES
/// ──────────
/// * Never blocks the UI isolate: everything is fire-and-forget.
/// * Never throws, never reports its own failures through `Observability`
///   (that would feed back into this very reporter).
/// * No personal data: free text is scrubbed, no user id is sent (the server
///   derives the reporter from the JWT), only an allow-list of context keys
///   is forwarded.
class IncidentReporter implements CrashReporter {
  IncidentReporter({
    IncidentTransport? transport,
    String? Function()? userIdProvider,
    String? Function()? screenProvider,
    DateTime Function()? now,
    FlushScheduler? scheduler,
    FingerprintThrottle? throttle,
    String? sessionId,
    String? platform,
  }) : _transport = transport ?? _rpcTransport,
       _userIdProvider = userIdProvider ?? _supabaseUserId,
       _screenProvider = screenProvider ?? _trackerScreen,
       _now = now ?? DateTime.now,
       _scheduler = scheduler ?? _timerScheduler,
       _throttle = throttle ?? FingerprintThrottle(now: now),
       _sessionId = sessionId ?? _newSessionId(),
       _platform = platform ?? _currentPlatform();

  /// Process-wide instance used by `app_bootstrap.dart`.
  static final IncidentReporter instance = IncidentReporter();

  static const String rpcName = 'incident_report_batch';

  /// A pending buffer is flushed after this long...
  static const Duration flushInterval = Duration(seconds: 30);

  /// ...or as soon as it holds this many reports.
  static const int flushThreshold = 10;

  /// Server-side cap per RPC call.
  static const int maxBatchSize = 20;

  /// Hard cap on reports waiting for delivery (offline / signed out).
  static const int maxBuffered = 50;

  /// Delivery attempts before a report is dropped.
  static const int maxAttempts = 3;

  static const Duration requestTimeout = Duration(seconds: 10);
  static const Duration maxBackoff = Duration(minutes: 5);

  static const int _maxBreadcrumbs = 10;
  static const int _maxContextChars = 4000;

  /// Custom keys that may be forwarded. Everything else is ignored.
  static const Set<String> _contextKeyAllowList = {
    'network_online',
    'supabase_ready',
    'session_state',
  };

  final IncidentTransport _transport;
  final String? Function() _userIdProvider;
  final String? Function() _screenProvider;
  final DateTime Function() _now;
  final FlushScheduler _scheduler;
  final FingerprintThrottle _throttle;
  final String _sessionId;
  final String _platform;

  final List<_QueuedReport> _buffer = [];
  final List<String> _breadcrumbs = [];
  final Map<String, Object> _customKeys = {};

  FlushCanceller? _cancelScheduled;
  Future<void>? _inFlight;
  bool _enabled = true;

  // ── CrashReporter ──────────────────────────────────────────────────────

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    required ErrorCategory category,
    String? reason,
    Iterable<Object> information = const [],
    bool fatal = false,
  }) async {
    if (!_enabled) return;
    try {
      final overflow = error is LayoutOverflowException ? error.info : null;
      final fingerprint =
          overflow?.fingerprint ?? _genericFingerprint(error, stack, category);

      final suppressed = _throttle.tryAcquire(fingerprint);
      if (suppressed == null) return; // same fingerprint within 60 s

      final payload = _buildPayload(
        error: error,
        stack: stack,
        category: category,
        reason: reason,
        information: information,
        fatal: fatal,
        fingerprint: fingerprint,
        suppressed: suppressed,
        overflow: overflow,
      );

      _enqueue(_QueuedReport(payload), immediate: fatal);
    } catch (e) {
      _debug('record failed: $e');
    }
  }

  @override
  Future<void> log(String message) async {
    if (!_enabled) return;
    _breadcrumbs.add(TelemetryScrubber.scrubLine(message, maxLength: 120));
    while (_breadcrumbs.length > _maxBreadcrumbs) {
      _breadcrumbs.removeAt(0);
    }
  }

  @override
  Future<void> setCustomKey(String key, Object value) async {
    if (!_contextKeyAllowList.contains(key)) return;
    _customKeys[key] =
        (value is num || value is bool)
            ? value
            : TelemetryScrubber.scrubLine(value.toString(), maxLength: 60);
  }

  /// Intentionally a no-op: the server derives the reporter from the JWT, and
  /// we never want a user id (even hashed) inside a report payload.
  @override
  Future<void> setUserIdentifier(String identifier) async {}

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    _enabled = enabled;
    if (!enabled) {
      _cancelScheduled?.call();
      _cancelScheduled = null;
      _buffer.clear();
      _breadcrumbs.clear();
    }
  }

  // ── Delivery ───────────────────────────────────────────────────────────

  /// Sends everything buffered, in batches of at most [maxBatchSize].
  /// Always completes normally. Concurrent calls share one run.
  Future<void> flush() =>
      _inFlight ??= _drain().whenComplete(() {
        _inFlight = null;
      });

  void _enqueue(_QueuedReport report, {required bool immediate}) {
    _buffer.add(report);
    while (_buffer.length > maxBuffered) {
      _buffer.removeAt(0); // keep the newest
    }
    if (immediate || _buffer.length >= flushThreshold) {
      unawaited(flush());
    } else {
      _scheduleFlush(flushInterval);
    }
  }

  void _scheduleFlush(Duration delay) {
    if (_cancelScheduled != null) return;
    _cancelScheduled = _scheduler(delay, () {
      _cancelScheduled = null;
      unawaited(flush());
    });
  }

  Future<void> _drain() async {
    try {
      while (_enabled && _buffer.isNotEmpty) {
        // The RPC is granted to `authenticated` only. Keep the reports and
        // look again later instead of burning delivery attempts.
        if (_userIdProvider() == null) {
          _scheduleFlush(flushInterval);
          return;
        }

        final take = min(maxBatchSize, _buffer.length);
        final batch = _buffer.sublist(0, take);
        _buffer.removeRange(0, take);

        final delivered = await _send(batch);
        if (!delivered) {
          _requeue(batch);
          return;
        }
      }
    } catch (e) {
      _debug('drain failed: $e');
    }
  }

  /// `true` = done with this batch (delivered, or permanently rejected by the
  /// server). `false` = transient failure, try again later.
  Future<bool> _send(List<_QueuedReport> batch) async {
    try {
      final result = await _transport([
        for (final r in batch) r.payload,
      ]).timeout(requestTimeout);

      if (result is Map && result['ok'] == false) {
        // VALIDATION etc.: retrying the same payload cannot succeed.
        _debug('server rejected batch: ${result['code']}');
      }
      return true;
    } catch (e) {
      // Offline, Supabase down, not signed in, timeout... all silent.
      _debug('send failed: $e');
      return false;
    }
  }

  void _requeue(List<_QueuedReport> batch) {
    if (!_enabled) return;
    final retry = <_QueuedReport>[];
    for (final report in batch) {
      report.attempts++;
      if (report.attempts < maxAttempts) retry.add(report);
    }
    if (retry.isEmpty) return;

    _buffer.insertAll(0, retry);
    while (_buffer.length > maxBuffered) {
      _buffer.removeAt(0);
    }

    final backoff = flushInterval * (1 << retry.first.attempts);
    _scheduleFlush(backoff > maxBackoff ? maxBackoff : backoff);
  }

  // ── Payload ────────────────────────────────────────────────────────────

  static const Map<ErrorCategory, String> _serverCategory = {
    ErrorCategory.fatalCrash: 'crash',
    ErrorCategory.handledException: 'error',
    ErrorCategory.businessExpected: 'other',
    ErrorCategory.network: 'network',
    ErrorCategory.authentication: 'auth',
    ErrorCategory.realtime: 'realtime',
    ErrorCategory.cache: 'error',
    ErrorCategory.database: 'error',
    ErrorCategory.parsing: 'error',
    ErrorCategory.aiProvider: 'error',
    ErrorCategory.mediaUpload: 'upload',
    ErrorCategory.layoutOverflow: 'other',
  };

  Map<String, dynamic> _buildPayload({
    required Object error,
    required StackTrace? stack,
    required ErrorCategory category,
    required String? reason,
    required Iterable<Object> information,
    required bool fatal,
    required String fingerprint,
    required int suppressed,
    required OverflowInfo? overflow,
  }) {
    final isOverflow = overflow != null;

    final String title;
    final String message;
    if (overflow != null) {
      title = overflow.title;
      message = overflow.summary;
    } else {
      final firstLine = TelemetryScrubber.scrubLine(
        _firstLine(error),
        maxLength: 160,
      );
      title = TelemetryScrubber.scrubLine(
        '${error.runtimeType}: $firstLine',
        maxLength: 200,
      );
      message = TelemetryScrubber.scrub(_safeToString(error), maxLength: 1000);
    }

    final context = <String, Object>{
      'kind': category.key,
      'fatal': fatal,
      'environment': BuildInfo.environment,
      'commit_sha': BuildInfo.commitSha,
      ..._customKeys,
      if (overflow != null) ...overflow.toContext(),
    };

    if (!isOverflow) {
      context['error_type'] = error.runtimeType.toString();
      final screen = TelemetryScrubber.scrubLine(_screenProvider());
      if (screen.isNotEmpty) context['screen'] = screen;
      final feature = _infoValue(information, 'feature: ');
      if (feature != null) {
        context['feature'] = TelemetryScrubber.scrubLine(
          feature,
          maxLength: 60,
        );
      }
      final operation = _infoValue(information, 'operation: ');
      if (operation != null) {
        context['operation'] = TelemetryScrubber.scrubLine(
          operation,
          maxLength: 60,
        );
      }
      if (reason != null && reason.isNotEmpty) {
        context['reason'] = TelemetryScrubber.scrubLine(reason, maxLength: 200);
      }
      if (_breadcrumbs.isNotEmpty) {
        context['breadcrumbs'] = List<String>.of(_breadcrumbs);
      }
    }
    if (suppressed > 0) context['suppressed_since_last'] = suppressed;

    if (jsonEncode(context).length > _maxContextChars) {
      context.remove('breadcrumbs');
    }

    final rawStack = isOverflow ? null : stack?.toString();

    return <String, dynamic>{
      'category': _serverCategory[category] ?? 'other',
      'severity':
          fatal
              ? 'fatal'
              : (isOverflow || category == ErrorCategory.layoutOverflow
                  ? 'warning'
                  : 'error'),
      'title': title,
      'message': message,
      'fingerprint': fingerprint,
      'platform': _platform,
      'app_version': BuildInfo.appVersion,
      'build_number': BuildInfo.buildNumber,
      'locale': _locale(),
      'session_id': _sessionId,
      'occurred_at': _now().toUtc().toIso8601String(),
      if (rawStack != null && rawStack.trim().isNotEmpty)
        'stack_trace': TelemetryScrubber.scrub(rawStack, maxLength: 3000),
      'context': context,
    };
  }

  String _genericFingerprint(
    Object error,
    StackTrace? stack,
    ErrorCategory category,
  ) {
    final frame = OverflowFilter.topUserFrame(stack)?.token ?? 'no_user_frame';
    final message = TelemetryScrubber.normalizeForFingerprint(
      _firstLine(error),
    );
    final input = '${category.key}|${error.runtimeType}|$message|$frame';
    return sha256.convert(utf8.encode(input)).toString().substring(0, 32);
  }

  static String? _infoValue(Iterable<Object> information, String prefix) {
    for (final item in information) {
      final text = item.toString();
      if (text.startsWith(prefix)) return text.substring(prefix.length);
    }
    return null;
  }

  static String _safeToString(Object error) {
    try {
      return error.toString();
    } catch (_) {
      return error.runtimeType.toString();
    }
  }

  static String _firstLine(Object error) =>
      _safeToString(error).split('\n').first;

  static String? _locale() {
    try {
      return PlatformDispatcher.instance.locale.toLanguageTag();
    } catch (_) {
      return null;
    }
  }

  // ── Defaults ───────────────────────────────────────────────────────────

  static Future<Object?> _rpcTransport(
    List<Map<String, dynamic>> reports,
  ) async {
    return await SupabaseProvider.client.rpc(
      rpcName,
      params: {'p_reports': reports},
    );
  }

  static String? _supabaseUserId() => SupabaseProvider.idOrNull;

  static String? _trackerScreen() => ActiveScreenTracker.currentRoute;

  static FlushCanceller _timerScheduler(
    Duration delay,
    void Function() callback,
  ) {
    final timer = Timer(delay, callback);
    return timer.cancel;
  }

  static String _currentPlatform() {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'other',
    };
  }

  /// Random per-process id so occurrences from one launch can be correlated.
  /// Not derived from the user or the device.
  static String _newSessionId() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  static void _debug(String message) {
    if (kDebugMode) {
      debugPrint('📡 IncidentReporter: $message');
    }
  }

  // ── Testing ────────────────────────────────────────────────────────────

  @visibleForTesting
  int get bufferedCount => _buffer.length;

  @visibleForTesting
  List<Map<String, dynamic>> get bufferedPayloads => [
    for (final r in _buffer) r.payload,
  ];

  @visibleForTesting
  void resetForTest() {
    _cancelScheduled?.call();
    _cancelScheduled = null;
    _buffer.clear();
    _breadcrumbs.clear();
    _customKeys.clear();
    _throttle.clear();
    _enabled = true;
  }
}

class _QueuedReport {
  _QueuedReport(this.payload);

  final Map<String, dynamic> payload;
  int attempts = 0;
}
