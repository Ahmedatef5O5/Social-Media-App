import 'package:supabase_flutter/supabase_flutter.dart';

import '../errors/exceptions.dart';
import '../errors/network_error_utils.dart';
import '../supabase/supabase_provider.dart';

/// How an error should be treated by the observability pipeline.
enum ReportingPolicy {
  /// Crashlytics fatal. Reserved for errors that genuinely killed a frame
  /// or an isolate and left the app in an undefined state.
  fatal,

  /// Crashlytics non-fatal. The app recovered, but engineering must see it.
  nonFatal,

  /// Console / breadcrumb only. Useful while debugging, noise in Crashlytics.
  logOnly,

  /// Never leaves the device. Expected, user-driven, or environmental.
  ignore,
}

/// Domain classification for every error the app catches.
///
/// Keeping these as an enum (instead of free-form strings at each call
/// site) is what makes Crashlytics groupable and what makes
/// [ErrorClassifier] unit-testable.
enum ErrorCategory {
  fatalCrash(ReportingPolicy.fatal),
  handledException(ReportingPolicy.nonFatal),
  businessExpected(ReportingPolicy.ignore),
  network(ReportingPolicy.logOnly),
  authentication(ReportingPolicy.nonFatal),
  realtime(ReportingPolicy.nonFatal),
  cache(ReportingPolicy.nonFatal),
  database(ReportingPolicy.nonFatal),
  parsing(ReportingPolicy.nonFatal),
  aiProvider(ReportingPolicy.nonFatal),
  mediaUpload(ReportingPolicy.nonFatal);

  const ErrorCategory(this.policy);

  final ReportingPolicy policy;

  bool get shouldReportToCrashlytics =>
      policy == ReportingPolicy.fatal || policy == ReportingPolicy.nonFatal;

  bool get isFatal => policy == ReportingPolicy.fatal;

  /// Stable string used as a Crashlytics custom key / log prefix.
  String get key => name;
}

/// Turns a raw caught object into an [ErrorCategory].
///
/// Deliberately mirrors the precedence order already used by
/// `SupabaseErrorMapper.toUserMessage`, so the category a user-facing
/// message came from and the category Crashlytics records can never drift
/// apart.
class ErrorClassifier {
  const ErrorClassifier._();

  /// Sentinel thrown across the app (see `posts_services.dart`,
  /// `chat_services.dart`) when the pre-flight connectivity probe fails.
  static const String noInternetSentinel = 'no-internet';

  static ErrorCategory classify(Object error) {
    // 1. User-driven cancellation is never an incident.
    if (error is UploadCanceledException) {
      return ErrorCategory.businessExpected;
    }

    final text = error.toString().toLowerCase();

    if (text.contains(noInternetSentinel)) {
      return ErrorCategory.network;
    }

    // 2. Connectivity. Never a Crashlytics event — it is the user's tunnel,
    //    not our bug. Kept as a breadcrumb so it still appears in the
    //    timeline of a later real crash.
    if (NetworkErrorUtils.isNetworkError(error) ||
        NetworkErrorUtils.isTimeoutError(error)) {
      return ErrorCategory.network;
    }

    // 3. Auth. Wrong-password style failures are expected; anything else
    //    (refresh failure, malformed session) is a real signal.
    if (error is AuthException) {
      final code = error.code ?? '';
      const expected = {
        'invalid_credentials',
        'user_already_exists',
        'email_not_confirmed',
        'over_email_send_rate_limit',
        'weak_password',
      };
      if (expected.contains(code)) {
        return ErrorCategory.businessExpected;
      }
      return ErrorCategory.authentication;
    }

    if (error is UnauthenticatedException) {
      return ErrorCategory.authentication;
    }

    // 4. Realtime. Supabase surfaces channel failures as this type.
    if (error is RealtimeSubscribeException ||
        text.contains('realtimesubscribe')) {
      return ErrorCategory.realtime;
    }

    // 5. Storage / media.
    if (error is StorageException) {
      return ErrorCategory.mediaUpload;
    }

    // 6. Database / PostgREST.
    if (error is PostgrestException) {
      // PGRST116 = .single() matched zero rows. Common, expected, and
      // already handled by every caller — reporting it would drown the
      // Crashlytics dashboard.
      if ((error.code ?? '') == 'PGRST116') {
        return ErrorCategory.businessExpected;
      }
      return ErrorCategory.database;
    }

    // 7. Deserialization. These are the ones that silently corrupt caches.
    if (error is FormatException ||
        error is TypeError ||
        text.contains('is not a subtype of')) {
      return ErrorCategory.parsing;
    }

    // 8. Local cache / Hive.
    if (text.contains('hiveerror') ||
        text.contains('box not found') ||
        text.contains('box has already been closed')) {
      return ErrorCategory.cache;
    }

    return ErrorCategory.handledException;
  }
}
