import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'crash_reporter.dart';
import 'error_category.dart';

/// The only file in the app that imports `firebase_crashlytics`.
///
/// Everything else depends on [CrashReporter], which is what keeps the
/// test suite Firebase-free.
class CrashlyticsReporter implements CrashReporter {
  CrashlyticsReporter([FirebaseCrashlytics? crashlytics])
    : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  final FirebaseCrashlytics _crashlytics;

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    required ErrorCategory category,
    String? reason,
    Iterable<Object> information = const [],
    bool fatal = false,
  }) {
    return _crashlytics.recordError(
      error,
      stack,
      reason: reason,
      information: information,
      fatal: fatal,
    );
  }

  @override
  Future<void> log(String message) => _crashlytics.log(message);

  @override
  Future<void> setCustomKey(String key, Object value) =>
      _crashlytics.setCustomKey(key, value);

  @override
  Future<void> setUserIdentifier(String identifier) =>
      _crashlytics.setUserIdentifier(identifier);

  @override
  Future<void> setCollectionEnabled(bool enabled) =>
      _crashlytics.setCrashlyticsCollectionEnabled(enabled);
}
