import 'error_category.dart';

/// Minimal surface the app depends on. Keeping Crashlytics behind this
/// interface is what lets every unit test run without Firebase, and what
/// keeps `flutter test` hermetic on a CI runner with no google-services.json.
abstract class CrashReporter {
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    required ErrorCategory category,
    String? reason,
    Iterable<Object> information = const [],
    bool fatal = false,
  });

  Future<void> log(String message);

  Future<void> setCustomKey(String key, Object value);

  Future<void> setUserIdentifier(String identifier);

  Future<void> setCollectionEnabled(bool enabled);
}

/// Used in debug, in tests, and as the pre-Firebase placeholder during
/// startup. Does nothing, never throws.
class NoopCrashReporter implements CrashReporter {
  const NoopCrashReporter();

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    required ErrorCategory category,
    String? reason,
    Iterable<Object> information = const [],
    bool fatal = false,
  }) async {}

  @override
  Future<void> log(String message) async {}

  @override
  Future<void> setCustomKey(String key, Object value) async {}

  @override
  Future<void> setUserIdentifier(String identifier) async {}

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}
}

/// Records everything in memory. Used by tests — it is what lets a test
/// assert "this failure produced exactly one non-fatal report in the
/// `realtime` category" with no Firebase dependency at all.
class RecordingCrashReporter implements CrashReporter {
  final List<RecordedError> errors = [];
  final List<String> logs = [];
  final Map<String, Object> customKeys = {};
  String? userIdentifier;
  bool collectionEnabled = true;

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    required ErrorCategory category,
    String? reason,
    Iterable<Object> information = const [],
    bool fatal = false,
  }) async {
    errors.add(
      RecordedError(
        error: error,
        stack: stack,
        category: category,
        reason: reason,
        information: information.toList(),
        fatal: fatal,
      ),
    );
  }

  @override
  Future<void> log(String message) async => logs.add(message);

  @override
  Future<void> setCustomKey(String key, Object value) async {
    customKeys[key] = value;
  }

  @override
  Future<void> setUserIdentifier(String identifier) async {
    userIdentifier = identifier;
  }

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    collectionEnabled = enabled;
  }

  void clear() {
    errors.clear();
    logs.clear();
    customKeys.clear();
    userIdentifier = null;
  }

  Iterable<RecordedError> ofCategory(ErrorCategory category) =>
      errors.where((e) => e.category == category);
}

class RecordedError {
  const RecordedError({
    required this.error,
    required this.stack,
    required this.category,
    required this.reason,
    required this.information,
    required this.fatal,
  });

  final Object error;
  final StackTrace? stack;
  final ErrorCategory category;
  final String? reason;
  final List<Object> information;
  final bool fatal;

  @override
  String toString() =>
      'RecordedError(${category.key}, fatal: $fatal, reason: $reason, '
      'error: $error)';
}
