import 'package:flutter/foundation.dart';
import 'error_category.dart';
import 'observability.dart';

/// Thin, deliberately small logging front-end.
///
/// The codebase currently calls `debugPrint` in ~hundreds of places. This
/// class is NOT an attempt to replace all of them at once — that would be a
/// mechanical churn PR with no behavioural benefit. It exists so that:
///
///  * new code has one obvious way to log,
///  * the log ALSO becomes a Crashlytics breadcrumb, which `debugPrint`
///    never does (a `debugPrint` is invisible in production — this is
///    precisely why the V6 audit scored observability 0.5/10),
///  * error paths route through [Observability] and get classified.
///
/// Migration is incremental: convert a `debugPrint` to `AppLogger` when you
/// are already touching that line for another reason.
class AppLogger {
  const AppLogger(this.tag);

  /// Feature / subsystem name, e.g. `'chat_details'`, `'presence'`.
  final String tag;

  /// Developer-only. Never leaves the device, never becomes a breadcrumb.
  void debug(String message) {
    if (kDebugMode) {
      debugPrint('🔎 [$tag] $message');
    }
  }

  /// Notable lifecycle event. Becomes a Crashlytics breadcrumb.
  void info(String message) {
    obs.breadcrumb(message, feature: tag);
  }

  /// Something recoverable went wrong. Breadcrumb only, no issue created.
  void warn(String message) {
    obs.breadcrumb('WARN $message', feature: tag);
  }

  /// Something went wrong that engineering needs to see. Classified and
  /// forwarded to Crashlytics according to [ErrorCategory.policy].
  void error(
    Object error,
    StackTrace? stack, {
    String? operation,
    ErrorCategory? category,
    String? reason,
  }) {
    obs.recordError(
      error,
      stack,
      category: category,
      feature: tag,
      operation: operation,
      reason: reason,
    );
  }
}
