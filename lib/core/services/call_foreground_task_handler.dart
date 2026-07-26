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
/// - `ZegoGroupCallView` → group calls, serviceId: 102
/// - `main.dart` (`CallCubit` → `CallConnectedState` listener) → 1:1 calls, serviceId: 101
@pragma('vm:entry-point')
void startCallServiceCallback() {
  FlutterForegroundTask.setTaskHandler(CallForegroundTaskHandler());
}

/// Keeps the app process alive while a Zego voice/video call (1:1 or
/// group) is ongoing and the app is backgrounded.
///
/// Intentionally minimal: it does NOT duplicate call business logic
/// (duration timers, participant state, etc.) — that already lives in
/// `CallCubit`, `GroupCallSignalingService`, and `ZegoGroupCallView`. This
/// handler's only job is OS compliance: without an active foreground
/// service, Android can suspend the isolate hosting ZegoUIKit's WebRTC
/// engine a few seconds after the app is minimized, which would drop
/// the call's audio/video.
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
    // Reserved two-way channel: the UI isolate could call
    // `FlutterForegroundTask.sendDataToTask(...)` in the future if this
    // handler ever needs to react to app-side events. Not required today
    // since `ZegoGroupCallView._terminateCall` / `CallCubit.endCall`
    // already call `FlutterForegroundTask.stopService()` directly.
    debugPrint('[CallForegroundTaskHandler] onReceiveData: $data');
  }
}
