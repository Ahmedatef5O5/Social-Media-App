import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/bootstrap/app_bootstrap.dart';
import 'core/errors/network_error_utils.dart';
import 'core/toast/app_toast.dart';

void main() {
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Framework-level errors (build/layout/paint) — log always,
      // and still show the red screen in debug so nothing is hidden
      // from you during development.
      FlutterError.onError = (details) {
        FlutterError.dumpErrorToConsole(details);
        _notifyUserOfUncaughtError(details.exception);
      };

      // Platform-level errors that escape everything else (e.g. from
      // native channel callbacks).
      PlatformDispatcher.instance.onError = (error, stack) {
        debugPrint('PlatformDispatcher error: $error\n$stack');
        _notifyUserOfUncaughtError(error);
        return true;
      };

      try {
        await initializeApp();
      } catch (e, s) {
        debugPrint('❌ Critical bootstrap failure: $e\n$s');
      }

      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString('user_theme_key') ?? 'ocean';

      runApp(buildApp(savedTheme));
    },
    (error, stack) {
      debugPrint('Uncaught zone error: $error\n$stack');
      _notifyUserOfUncaughtError(error);
    },
  );
}

DateTime? _lastGlobalErrorToastAt;

void _notifyUserOfUncaughtError(Object error) {
  final errorString = error.toString();

  if (NetworkErrorUtils.isNetworkError(error) ||
      NetworkErrorUtils.isTimeoutError(error) ||
      errorString.contains('VideoError') ||
      errorString.contains('ExoPlaybackException') ||
      errorString.contains('RealtimeSubscribeException') ||
      errorString.contains('HttpException: Invalid statusCode: 404') ||
      errorString.contains('RealtimeSubscribeStatus.timedOut')) {
    debugPrint('Uncaught error suppressed from UI: $error');
    return;
  }

  final now = DateTime.now();
  if (_lastGlobalErrorToastAt != null &&
      now.difference(_lastGlobalErrorToastAt!) < const Duration(seconds: 4)) {
    return;
  }

  _lastGlobalErrorToastAt = now;

  WidgetsBinding.instance.addPostFrameCallback((_) {
    AppToast.error('Something went wrong. Please try again.');
  });
}
