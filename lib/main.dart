import 'dart:async';
import 'app.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'core/bootstrap/app_bootstrap.dart';
import 'core/errors/network_error_utils.dart';
import 'core/observability/error_category.dart';
import 'core/observability/observability.dart';
import 'core/toast/app_toast.dart';

void main() {
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // ── Error handlers are installed FIRST, before Firebase exists ──
      //
      // Observability buffers everything until `attachReporter` runs inside
      // `initializeCriticalBeforeRunApp()`, so a crash during Firebase
      // initialisation itself is still captured and flushed afterwards.
      // This is the whole reason `Observability` is a facade with a pending
      // queue instead of a direct `FirebaseCrashlytics.instance` call.

      // Framework-level errors (build/layout/paint) — log always,
      // and still show the red screen in debug so nothing is hidden
      // from you during development.
      FlutterError.onError = (details) {
        FlutterError.dumpErrorToConsole(details);
        unawaited(obs.recordFlutterError(details));
        _notifyUserOfUncaughtError(details.exception);
      };

      // Platform-level errors that escape everything else (e.g. from
      // native channel callbacks).
      PlatformDispatcher.instance.onError = (error, stack) {
        unawaited(
          obs.recordError(
            error,
            stack,
            category: ErrorCategory.fatalCrash,
            feature: 'platform_dispatcher',
            fatal: true,
          ),
        );
        _notifyUserOfUncaughtError(error);
        return true;
      };

      await initializeCriticalBeforeRunApp();

      const defaultThemeName = 'ocean';

      runApp(buildApp(defaultThemeName));

      startCoreServicesBootstrap();
    },

    (error, stack) {
      // Uncaught zone errors are, by definition, errors nothing else
      // handled. They are fatal even when the UI happens to survive.
      unawaited(
        obs.recordError(
          error,
          stack,
          category: ErrorCategory.fatalCrash,
          feature: 'root_zone',
          fatal: true,
        ),
      );
      _notifyUserOfUncaughtError(error);
    },
  );
}

DateTime? _lastGlobalErrorToastAt;

void _notifyUserOfUncaughtError(Object error) {
  if (!kDebugMode) {
    return;
  }

  final errorString = error.toString();

  if (NetworkErrorUtils.isNetworkError(error) ||
      NetworkErrorUtils.isTimeoutError(error) ||
      errorString.contains('PGRST303') ||
      errorString.contains('JWT issued at future') ||
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
    AppToast.error('Debug Error: ${error.toString().split('\n').first}');
  });
}
