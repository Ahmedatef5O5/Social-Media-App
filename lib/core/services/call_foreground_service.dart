import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';
import 'call_foreground_task_handler.dart';

class CallForegroundService {
  const CallForegroundService._();

  static bool _isRunning = false;

  static bool get isRunning => _isRunning;

  static Future<bool> start({
    required int serviceId,
    required String title,
    required String text,
    bool isVideo = false,
  }) async {
    try {
      if (!await Permission.microphone.isGranted) {
        debugPrint(
          '[CallForegroundService] microphone not granted — not starting '
          'the foreground service (Android 14+ would throw)',
        );
        return false;
      }
      if (isVideo && !await Permission.camera.isGranted) {
        debugPrint(
          '[CallForegroundService] camera not granted for a video call — '
          'not starting the foreground service',
        );
        return false;
      }

      await FlutterForegroundTask.startService(
        serviceId: serviceId,
        notificationTitle: title,
        notificationText: text,
        callback: startCallServiceCallback,
      );
      _isRunning = true;
      return true;
    } catch (e, s) {
      debugPrint('[CallForegroundService] startService failed: $e\n$s');
      return false;
    }
  }

  static Future<void> stop() async {
    _isRunning = false;
    try {
      await FlutterForegroundTask.stopService();
    } catch (e) {
      debugPrint('[CallForegroundService] stopService failed: $e');
    }
  }
}
