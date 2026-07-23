import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../secrets/app_secrets.dart';

///   1. DNS lookup against multiple independent public resolvers
///   2. Raw TCP socket handshake against public IPs (bypasses DNS issues)
///   3. Direct reachability probe against our own backend (Supabase)

class NetworkStatusService {
  NetworkStatusService._();

  static final NetworkStatusService instance = NetworkStatusService._();

  static const Duration _lookupTimeout = Duration(seconds: 3);
  static const Duration _socketTimeout = Duration(seconds: 3);
  static const int _dnsPort = 53;

  // Independent providers so a single provider's outage never reads as
  // "no internet".
  static const List<String> _dnsProbeHosts = ['one.one.one.one', 'dns.google'];
  static const List<String> _socketProbeIps = ['1.1.1.1', '8.8.8.8'];

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 4),
      receiveTimeout: const Duration(seconds: 4),
      sendTimeout: const Duration(seconds: 4),
    ),
  );

  /// Public API kept identical to before — every existing caller
  /// (PostsServices, UserService, ChatServices, ...) needs zero changes.
  Future<bool> isConnected() async {
    if (await _dnsReachable()) return true;
    if (await _socketReachable()) return true;
    if (await _backendReachable()) return true;
    return false;
  }

  Future<bool> _dnsReachable() async {
    for (final host in _dnsProbeHosts) {
      try {
        final result = await InternetAddress.lookup(
          host,
        ).timeout(_lookupTimeout);
        if (result.isNotEmpty && result.first.rawAddress.isNotEmpty) {
          return true;
        }
      } catch (_) {
        // try the next resolver
      }
    }
    return false;
  }

  Future<bool> _socketReachable() async {
    for (final ip in _socketProbeIps) {
      Socket? socket;
      try {
        socket = await Socket.connect(ip, _dnsPort, timeout: _socketTimeout);
        return true;
      } catch (_) {
        // try the next IP
      } finally {
        socket?.destroy();
      }
    }
    return false;
  }

  Future<bool> _backendReachable() async {
    try {
      final response = await _dio.head(
        AppSecrets.supabaseUrl,
        options: Options(
          validateStatus: (_) => true,
          followRedirects: true,
          maxRedirects: 2,
        ),
      );
      final reachable = response.statusCode != null;
      debugPrint(
        '[NetworkStatusService] backend probe → ${response.statusCode} | reachable: $reachable',
      );
      return reachable;
    } on DioException catch (e) {
      // A "bad response" still means a server replied — we ARE connected.
      if (e.type == DioExceptionType.badResponse) return true;
      debugPrint('[NetworkStatusService] backend probe failed: ${e.type}');
      return false;
    } catch (_) {
      return false;
    }
  }
}