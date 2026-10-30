import 'crash_reporter.dart';
import 'error_category.dart';

/// Fans every call out to all [delegates] (e.g. Crashlytics + incidents).
///
/// Delegates run concurrently and are isolated from each other: one that
/// throws or hangs on error never prevents the others from receiving the call,
/// and the composite itself never throws.
class CompositeCrashReporter implements CrashReporter {
  CompositeCrashReporter(Iterable<CrashReporter> delegates)
    : delegates = List.unmodifiable(delegates);

  final List<CrashReporter> delegates;

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    required ErrorCategory category,
    String? reason,
    Iterable<Object> information = const [],
    bool fatal = false,
  }) => _fanOut(
    (r) => r.recordError(
      error,
      stack,
      category: category,
      reason: reason,
      information: information,
      fatal: fatal,
    ),
  );

  @override
  Future<void> log(String message) => _fanOut((r) => r.log(message));

  @override
  Future<void> setCustomKey(String key, Object value) =>
      _fanOut((r) => r.setCustomKey(key, value));

  @override
  Future<void> setUserIdentifier(String identifier) =>
      _fanOut((r) => r.setUserIdentifier(identifier));

  @override
  Future<void> setCollectionEnabled(bool enabled) =>
      _fanOut((r) => r.setCollectionEnabled(enabled));

  Future<void> _fanOut(Future<void> Function(CrashReporter) call) async {
    await Future.wait([for (final d in delegates) _guard(d, call)]);
  }

  Future<void> _guard(
    CrashReporter delegate,
    Future<void> Function(CrashReporter) call,
  ) async {
    try {
      await call(delegate);
    } catch (_) {
      // A broken sink must never break the others (or the app).
    }
  }
}
