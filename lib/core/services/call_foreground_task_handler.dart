import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Top-level entry-point required by `flutter_foreground_task`.
///
/// Must stay a top-level function (not a class method) and keep the
/// `@pragma('vm:entry-point')` annotation, or the Android engine will not
/// be able to locate it from the background isolate when the service
/// starts (especially after a cold restart by the OS).
///
/// Shared by both call flows:
/// - `LivekitGroupCallView` → group calls, serviceId: 102
/// - `main.dart` (`CallCubit` → `CallConnectedState` listener) → 1:1 calls, serviceId: 101
@pragma('vm:entry-point')
void startCallServiceCallback() {
  FlutterForegroundTask.setTaskHandler(CallForegroundTaskHandler());
}

/// Message sent from the service isolate to the UI isolate when the ongoing
/// call notification is tapped.
const String expandActiveCallMessage = 'expand_active_call';

class CallForegroundTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint(
      '[CallForegroundTaskHandler] started (starter: ${starter.name})',
    );
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // No periodic work today — `foregroundTaskOptions.eventAction` is set
    // to `.nothing()` in `app_bootstrap.dart`, so this is effectively a
    // no-op. Left as an extension point (e.g. a future "is the call still
    // active?" heartbeat) without needing to touch the call sites again.
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    debugPrint('[CallForegroundTaskHandler] destroyed');
  }

  @override
  void onReceiveData(Object data) {
    debugPrint('[CallForegroundTaskHandler] onReceiveData: $data');
  }

  /// The user tapped the ongoing-call notification ("Tap to return to the
  /// call"). Bring the app forward AND ask the UI isolate to expand the
  /// minimized call — see `_onForegroundTaskData` in `app.dart`.
  ///
  /// This handler runs in the service isolate, so it can only signal the main
  /// isolate through the communication port.
  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
    FlutterForegroundTask.sendDataToMain(expandActiveCallMessage);
  }
}
