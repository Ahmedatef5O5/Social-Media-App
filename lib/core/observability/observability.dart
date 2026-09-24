import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import 'crash_reporter.dart';
import 'error_category.dart';

/// Single entry point for production diagnostics.
///
/// WHY A FACADE AND NOT `FirebaseCrashlytics.instance` DIRECTLY
/// ───────────────────────────────────────────────────────────
/// 1. `main.dart` installs `FlutterError.onError` and
///    `PlatformDispatcher.instance.onError` BEFORE Firebase is initialized
///    (it has to — a crash during `Firebase.initializeApp` must still be
///    catchable). [Observability] therefore buffers reports until a real
///    reporter is attached, then flushes them. Nothing is lost.
/// 2. Every unit test can attach a [RecordingCrashReporter] and assert on
///    what would have been sent, with zero Firebase in the test process.
/// 3. Categorisation and PII scrubbing happen in exactly one place.
class Observability {
  Observability._();

  static final Observability instance = Observability._();

  /// Visible for testing only.
  @visibleForTesting
  static void resetForTest() {
    instance._reporter = const NoopCrashReporter();
    instance._pending.clear();
    instance._breadcrumbs.clear();
    instance._context.clear();
    instance._initialised = false;
  }

  CrashReporter _reporter = const NoopCrashReporter();
  final List<_PendingEvent> _pending = [];
  final List<String> _breadcrumbs = [];
  final Map<String, Object> _context = {};
  bool _initialised = false;

  static const int _maxPending = 64;
  static const int _maxBreadcrumbs = 60;

  /// Maximum number of buffered reports flushed on attach.
  bool get isInitialised => _initialised;

  CrashReporter get reporter => _reporter;

  /// Attaches the real reporter and flushes anything buffered during
  /// startup. Safe to call more than once (later calls replace the
  /// reporter, which is what tests rely on).
  Future<void> attachReporter(
    CrashReporter reporter, {
    required String environment,
    required String appVersion,
    required String buildNumber,
    bool collectionEnabled = true,
  }) async {
    _reporter = reporter;
    _initialised = true;

    await _safe(() => reporter.setCollectionEnabled(collectionEnabled));
    await setContext('environment', environment);
    await setContext('app_version', appVersion);
    await setContext('build_number', buildNumber);

    final buffered = List<_PendingEvent>.from(_pending);
    _pending.clear();
    for (final event in buffered) {
      await event.replay(reporter);
    }
  }

  // ── Context ────────────────────────────────────────────────────────────

  /// Sets a Crashlytics custom key. Values must already be non-sensitive:
  /// this method is NOT a scrubber, it is the place where the whitelist of
  /// keys is enforced by convention (see `docs/observability.md`).
  Future<void> setContext(String key, Object value) async {
    _context[key] = value;
    if (!_initialised) {
      _push(_PendingEvent.key(key, value));
      return;
    }
    await _safe(() => _reporter.setCustomKey(key, value));
  }

  Future<void> setScreen(String screen) => setContext('screen', screen);

  Future<void> setFeature(String feature) => setContext('feature', feature);

  Future<void> setNetworkState({required bool online}) =>
      setContext('network_online', online);

  /// Associates the crash with an account WITHOUT storing the raw Supabase
  /// user id. A stable SHA-256 prefix is enough to answer "is this one user
  /// or a thousand?" while keeping the report non-identifying.
  Future<void> setSessionUser(String? userId) async {
    if (userId == null || userId.isEmpty) {
      await setContext('session_state', 'anonymous');
      if (_initialised) {
        await _safe(() => _reporter.setUserIdentifier(''));
      }
      return;
    }
    final hashed = hashUserId(userId);
    await setContext('session_state', 'authenticated');
    if (!_initialised) {
      _push(_PendingEvent.user(hashed));
      return;
    }
    await _safe(() => _reporter.setUserIdentifier(hashed));
  }

  static String hashUserId(String userId) =>
      sha256.convert(utf8.encode(userId)).toString().substring(0, 12);

  Map<String, Object> get contextSnapshot => Map.unmodifiable(_context);

  // ── Breadcrumbs ────────────────────────────────────────────────────────

  /// A one-line, PII-free trail entry. Shows up above the stack trace in
  /// Crashlytics and is what turns "it crashed" into "it crashed right
  /// after the account switch".
  Future<void> breadcrumb(String message, {String? feature}) async {
    final line = feature == null ? message : '[$feature] $message';
    _breadcrumbs.add(line);
    if (_breadcrumbs.length > _maxBreadcrumbs) {
      _breadcrumbs.removeAt(0);
    }
    if (kDebugMode) {
      debugPrint('🧭 $line');
    }
    if (!_initialised) {
      _push(_PendingEvent.log(line));
      return;
    }
    await _safe(() => _reporter.log(line));
  }

  List<String> get breadcrumbs => List.unmodifiable(_breadcrumbs);

  // ── Errors ─────────────────────────────────────────────────────────────

  /// The single funnel every `catch` block in the app should call.
  ///
  /// [category] is optional: when omitted it is derived by
  /// [ErrorClassifier], which keeps call sites short and keeps the
  /// classification logic in one testable place.
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    ErrorCategory? category,
    String? reason,
    String? feature,
    String? operation,
    bool? fatal,
  }) async {
    final resolved = category ?? ErrorClassifier.classify(error);
    final isFatal = fatal ?? resolved.isFatal;

    if (kDebugMode) {
      debugPrint(
        '🛑 [${resolved.key}] ${feature ?? '-'}/${operation ?? '-'}: $error',
      );
    }

    if (!resolved.shouldReportToCrashlytics && !isFatal) {
      // Still worth a breadcrumb: a burst of `network` entries right before
      // a crash is itself diagnostic information.
      if (resolved.policy == ReportingPolicy.logOnly) {
        await breadcrumb(
          '${resolved.key}: ${_firstLine(error)}',
          feature: feature,
        );
      }
      return;
    }

    final information = <Object>[
      if (feature != null) 'feature: $feature',
      if (operation != null) 'operation: $operation',
      'category: ${resolved.key}',
      ..._context.entries.map((e) => '${e.key}: ${e.value}'),
    ];

    if (!_initialised) {
      _push(
        _PendingEvent.error(
          error,
          stack,
          resolved,
          reason ?? operation,
          information,
          isFatal,
        ),
      );
      return;
    }

    await _safe(
      () => _reporter.recordError(
        error,
        stack,
        category: resolved,
        reason: reason ?? operation,
        information: information,
        fatal: isFatal,
      ),
    );
  }

  /// Convenience for `FlutterError.onError`.
  Future<void> recordFlutterError(FlutterErrorDetails details) {
    return recordError(
      details.exception,
      details.stack,
      category: ErrorCategory.fatalCrash,
      reason: details.context?.toDescription(),
      feature: 'flutter_framework',
      fatal: true,
    );
  }

  // ── Timing ─────────────────────────────────────────────────────────────

  /// Measures a named operation. Emits a breadcrumb always, and a non-fatal
  /// report when the operation blows past [slowAfter] — that is how "the
  /// feed is slow for some users" becomes a searchable Crashlytics issue
  /// instead of a support ticket.
  Future<T> trace<T>(
    String operation,
    Future<T> Function() body, {
    String? feature,
    Duration slowAfter = const Duration(seconds: 5),
  }) async {
    final sw = Stopwatch()..start();
    try {
      final result = await body();
      sw.stop();
      await _finishTrace(operation, sw.elapsed, feature, slowAfter, null);
      return result;
    } catch (error, stack) {
      sw.stop();
      await _finishTrace(operation, sw.elapsed, feature, slowAfter, error);
      await recordError(
        error,
        stack,
        feature: feature,
        operation: operation,
        reason: 'failed after ${sw.elapsed.inMilliseconds}ms',
      );
      rethrow;
    }
  }

  Future<void> _finishTrace(
    String operation,
    Duration elapsed,
    String? feature,
    Duration slowAfter,
    Object? error,
  ) async {
    final ms = elapsed.inMilliseconds;
    await breadcrumb(
      '$operation ${error == null ? 'ok' : 'failed'} in ${ms}ms',
      feature: feature,
    );
    await setContext('last_${operation}_ms', ms);
    if (error == null && elapsed > slowAfter) {
      await recordError(
        SlowOperationException(operation, elapsed),
        StackTrace.current,
        category: ErrorCategory.handledException,
        feature: feature,
        operation: operation,
        reason: 'slow operation',
      );
    }
  }

  // ── Internals ──────────────────────────────────────────────────────────

  void _push(_PendingEvent event) {
    if (_pending.length >= _maxPending) {
      _pending.removeAt(0);
    }
    _pending.add(event);
  }

  Future<void> _safe(Future<void> Function() body) async {
    try {
      await body();
    } catch (e) {
      // Observability must never be the thing that crashes the app.
      if (kDebugMode) {
        debugPrint('⚠️ Observability sink failed: $e');
      }
    }
  }

  static String _firstLine(Object error) => error.toString().split('\n').first;
}

/// Raised internally (never thrown to callers) so a slow operation gets its
/// own Crashlytics issue with a stable title.
class SlowOperationException implements Exception {
  const SlowOperationException(this.operation, this.elapsed);

  final String operation;
  final Duration elapsed;

  @override
  String toString() =>
      'SlowOperationException: $operation took ${elapsed.inMilliseconds}ms';
}

class _PendingEvent {
  _PendingEvent._(this._replay);

  final Future<void> Function(CrashReporter reporter) _replay;

  Future<void> replay(CrashReporter reporter) => _replay(reporter);

  factory _PendingEvent.log(String line) => _PendingEvent._((r) => r.log(line));

  factory _PendingEvent.key(String key, Object value) =>
      _PendingEvent._((r) => r.setCustomKey(key, value));

  factory _PendingEvent.user(String hashed) =>
      _PendingEvent._((r) => r.setUserIdentifier(hashed));

  factory _PendingEvent.error(
    Object error,
    StackTrace? stack,
    ErrorCategory category,
    String? reason,
    List<Object> information,
    bool fatal,
  ) {
    return _PendingEvent._(
      (r) => r.recordError(
        error,
        stack,
        category: category,
        reason: reason,
        information: information,
        fatal: fatal,
      ),
    );
  }
}

/// Short alias used at call sites so instrumentation stays unobtrusive.
Observability get obs => Observability.instance;
