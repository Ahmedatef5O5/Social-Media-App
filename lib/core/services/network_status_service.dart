import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../secrets/app_secrets.dart';

class NetworkStatusService {
  NetworkStatusService._();

  static final NetworkStatusService instance = NetworkStatusService._();

  final _connectivity = Connectivity();

  final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 4),
      receiveTimeout: const Duration(seconds: 4),
      sendTimeout: const Duration(seconds: 4),
    ),
  );

  Future<bool> isConnected() async {
    try {
      final result = await _connectivity.checkConnectivity();
      if (result.contains(ConnectivityResult.none)) {
        return false;
      }
    } catch (_) {}

    return _httpProbe();
  }

  Future<bool> _httpProbe() async {
    try {
      final response = await _dio.head(
        AppSecrets.supabaseUrl,
        options: Options(
          validateStatus: (_) => true,
          followRedirects: true,
          maxRedirects: 2,
        ),
      );
      final hasConnection = response.statusCode != null;
      debugPrint(
        '[NetworkStatusService] probe → ${response.statusCode} | connected: $hasConnection',
      );
      return hasConnection;
    } on DioException catch (e) {
      debugPrint(
        '[NetworkStatusService] probe failed: ${e.type} — ${e.message}',
      );

      if (e.type == DioExceptionType.badResponse) {
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
