/// One performance sample, already sanitised and ready for
/// `public.log_performance_batch` (migration 018).
///
/// PRIVACY CONTRACT (enforced here, mirrored by CHECK constraints in SQL)
/// ─────────────────────────────────────────────────────────────────────
/// * `operation_name` is a low-cardinality identifier (`rpc:get_feed`), never a
///   URL, never a query string, never an id, e-mail or message text.
/// * `error_code` is a short machine code (`timeout`, `http_503`), never an
///   exception message.
/// * No user id is sent: the server derives it from the JWT.
///
/// Pure Dart: Shorebird Type A (patchable over the air).
library;

/// The four categories accepted by the server (`performance_metrics.metric_category`).
enum MetricCategory {
  apiRpc('api_rpc'),
  upload('upload'),
  callConnect('call_connect'),
  messageDelivery('message_delivery');

  const MetricCategory(this.wire);

  /// Value stored in the database.
  final String wire;
}

/// Well-known error codes. Anything else is passed through [sanitizeErrorCode].
abstract final class MetricErrorCodes {
  static const String timeout = 'timeout';
  static const String network = 'network';

  /// A cancelled upload is NOT a failure: it is never recorded (the server also
  /// excludes it from the success-rate denominator).
  static const String userCancelled = 'user_cancelled';
  static const String unknown = 'unknown';

  static String http(int status) => 'http_$status';
}

final RegExp _uuidPattern = RegExp(
  r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}',
);
final RegExp _digitRun = RegExp(r'\d{3,}');
final RegExp _illegalOperationChars = RegExp(r'[^a-z0-9_.:/-]');
final RegExp _repeatedUnderscore = RegExp(r'_{2,}');
final RegExp _illegalCodeChars = RegExp(r'[^A-Za-z0-9_.:-]');

/// Normalises an operation name to `^[a-z0-9_.:/-]{1,80}$` and strips anything
/// that looks like an identifier (UUIDs, runs of 3+ digits) or an address.
String sanitizeOperationName(String raw) {
  var s = raw.trim().toLowerCase();
  s = s.split('?').first; // never keep a query string
  s = s.replaceAll(_uuidPattern, 'id');
  s = s.replaceAll(_digitRun, 'n');
  s = s.replaceAll(_illegalOperationChars, '_');
  s = s.replaceAll(_repeatedUnderscore, '_');
  s = s.replaceAll(RegExp(r'^_+|_+$'), '');
  if (s.length > 80) s = s.substring(0, 80);
  return s.isEmpty ? 'unknown' : s;
}

/// Normalises an error code to `^[A-Za-z0-9_.:-]{1,64}$`; `null` stays `null`.
String? sanitizeErrorCode(String? raw) {
  if (raw == null) return null;
  var s = raw.trim().replaceAll(_illegalCodeChars, '_');
  s = s.replaceAll(_repeatedUnderscore, '_');
  if (s.length > 64) s = s.substring(0, 64);
  return s.isEmpty ? null : s;
}

class PerformanceMetric {
  PerformanceMetric({
    required this.category,
    required String operationName,
    required int durationMs,
    required this.isSuccess,
    String? errorCode,
    required this.recordedAt,
    required this.sessionId,
    required this.appVersion,
  }) : operationName = sanitizeOperationName(operationName),
       durationMs = durationMs < 0 ? 0 : (durationMs > 600000 ? 600000 : durationMs),
       errorCode = sanitizeErrorCode(errorCode);

  final MetricCategory category;
  final String operationName;
  final int durationMs;

  /// Reliability-sense success: the server answered correctly. An HTTP 404 is a
  /// success here; only >= 500, timeouts and connection errors are failures.
  final bool isSuccess;
  final String? errorCode;
  final DateTime recordedAt;
  final String sessionId;
  final String appVersion;

  bool get isFailure => !isSuccess;

  /// Same sample, bound to [id]. Used when a sample was recorded before the
  /// session existed (bootstrap) and the id is resolved at flush time.
  PerformanceMetric withSessionId(String id) => PerformanceMetric(
    category: category,
    operationName: operationName,
    durationMs: durationMs,
    isSuccess: isSuccess,
    errorCode: errorCode,
    recordedAt: recordedAt,
    sessionId: id,
    appVersion: appVersion,
  );

  Map<String, dynamic> toJson() => {
    'session_id': sessionId,
    'metric_category': category.wire,
    'operation_name': operationName,
    'duration_ms': durationMs,
    'is_success': isSuccess,
    if (errorCode != null) 'error_code': errorCode,
    'app_version': appVersion,
    'recorded_at': recordedAt.toUtc().toIso8601String(),
  };

  @override
  String toString() =>
      'PerformanceMetric(${category.wire}/$operationName ${durationMs}ms '
      '${isSuccess ? 'ok' : 'FAIL:$errorCode'})';
}
