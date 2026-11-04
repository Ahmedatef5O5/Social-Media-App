import 'dart:async';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import '../performance_metric.dart';
import '../performance_tracker.dart';

/// Derives a LOW-CARDINALITY operation name from a Supabase request URL.
///
///   /rest/v1/rpc/get_feed        -> rpc:get_feed
///   /rest/v1/posts?select=*      -> rest:posts
///   /auth/v1/token               -> auth:token
///   /storage/v1/object/avatars/x -> storage:object
///   /functions/v1/send-push      -> fn:send-push
///
/// Query strings, ids and file names are never part of the result.
String operationNameForSupabaseUrl(Uri url) {
  final segments = url.pathSegments;
  if (segments.length < 2) return 'http:other';
  final area = segments[0];
  final rest = segments.length > 2 ? segments.sublist(2) : const <String>[];
  switch (area) {
    case 'rest':
      if (rest.isEmpty) return 'rest:root';
      if (rest.first == 'rpc' && rest.length > 1) return 'rpc:${rest[1]}';
      return 'rest:${rest.first}';
    case 'auth':
      return 'auth:${rest.isEmpty ? 'root' : rest.first}';
    case 'storage':
      return 'storage:${rest.isEmpty ? 'root' : rest.first}';
    case 'functions':
      return 'fn:${rest.isEmpty ? 'root' : rest.first}';
    default:
      return 'http:other';
  }
}

/// Wraps the `http.Client` used by supabase_flutter and records the duration and
/// outcome of every PostgREST / RPC / auth / storage / functions request.
///
/// ```dart
/// await Supabase.initialize(
///   url: ..., anonKey: ...,
///   httpClient: PerformanceHttpClient(http.Client()),   // <- the only change
/// );
/// ```
///
/// MEASURED INTERVAL: request start -> response headers received (streamed
/// response), i.e. the latency the caller waits before it can read anything.
///
/// SUCCESS SEMANTICS (reliability, not REST purity)
///  * HTTP < 500 (including 401/404/409): the server answered correctly ->
///    success. 4xx codes are still kept in `error_code` (`http_404`).
///  * HTTP >= 500, timeouts and connection errors: failure.
///
/// The telemetry's own RPCs are skipped (no feedback loop). Realtime uses
/// WebSockets and is covered by `RealtimeDiagnostics`, not by this client.
///
/// Pure Dart: Shorebird Type A.
class PerformanceHttpClient extends http.BaseClient {
  PerformanceHttpClient(
    this._inner, {
    PerformanceTracker? tracker,
    DateTime Function()? now,
  }) : _tracker = tracker ?? PerformanceTracker.instance,
       _now = now ?? DateTime.now;

  final http.Client _inner;
  final PerformanceTracker _tracker;
  final DateTime Function() _now;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final operation = operationNameForSupabaseUrl(request.url);
    final measured = !_isSelf(operation);
    final started = _now();

    try {
      final response = await _inner.send(request);
      if (measured) {
        final status = response.statusCode;
        final failed = status >= 500;
        _tracker.record(
          category: MetricCategory.apiRpc,
          operation: operation,
          duration: _now().difference(started),
          success: !failed,
          errorCode: status >= 400 ? MetricErrorCodes.http(status) : null,
        );
      }
      return response;
    } catch (e) {
      if (measured) {
        _tracker.record(
          category: MetricCategory.apiRpc,
          operation: operation,
          duration: _now().difference(started),
          success: false,
          errorCode: _codeFor(e),
        );
      }
      rethrow;
    }
  }

  @override
  void close() => _inner.close();

  static bool _isSelf(String operation) {
    if (!operation.startsWith('rpc:')) return false;
    return PerformanceTracker.selfRpcNames.contains(operation.substring(4));
  }

  static String _codeFor(Object e) {
    if (e is TimeoutException) return MetricErrorCodes.timeout;
    if (e is SocketException || e is http.ClientException) {
      return MetricErrorCodes.network;
    }
    return MetricErrorCodes.unknown;
  }
}
