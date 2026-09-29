import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';
import 'call_foreground_task_handler.dart';

class CallForegroundService {
  const CallForegroundService._();

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
      return true;
    } catch (e, s) {
      debugPrint('[CallForegroundService] startService failed: $e\n$s');
      return false;
    }
  }

  static Future<void> stop() async {
    try {
      await FlutterForegroundTask.stopService();
    } catch (e) {
      debugPrint('[CallForegroundService] stopService failed: $e');
    }
  }
}
