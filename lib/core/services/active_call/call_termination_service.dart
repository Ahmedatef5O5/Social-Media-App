import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

/// Centralizes the four steps that must ALWAYS happen together whenever a
/// call (1:1 or group) truly ends, regardless of whether the user is
/// currently looking at the full-screen call UI or at our minimized header.
///
/// Previously this sequence was duplicated (and partially re-implemented)
/// across `ZegoCallView`'s `onCallEnd` event and `ZegoGroupCallView`'s
/// `_terminateCall`. Now both paths — plus the new `ActiveCallHeaderWidget`
/// "End call" button, which has no `ZegoUIKitPrebuiltCall` widget mounted to
/// trigger the SDK's own hang-up flow — funnel through here.
class CallTerminationService {
  const CallTerminationService._();

  /// Runs the real termination sequence:
  /// 1. Leaves the Zego RTC room (stops publishing/playing audio & video).
  /// 2. Runs [signalEnd] — the caller's own app-level signaling
  ///    (`CallCubit.endCall` for 1:1, `GroupCallSignalingService.endCall`
  ///    for group), which updates Supabase and logs the call message.
  /// 3. Stops the `flutter_foreground_task` foreground service.
  /// 4. Resets Zego's mini-overlay state machine via `.minimize.hide()` —
  ///    documented by the SDK specifically for "call ended while
  ///    minimized, no need to navigate, just hide the minimize widget".
  ///
  /// Every step is best-effort: a failure in one step must not prevent the
  /// following ones from running, since leaving the user's UI/session in a
  /// half-ended state is worse than swallowing a secondary error.
  static Future<void> endActiveCall({
    required Future<void> Function() signalEnd,
  }) async {
    try {
      await ZegoUIKit().leaveRoom();
    } catch (e) {
      debugPrint('[CallTerminationService] leaveRoom failed: $e');
    }

    try {
      await signalEnd();
    } catch (e) {
      debugPrint('[CallTerminationService] signalEnd failed: $e');
    }

    try {
      await FlutterForegroundTask.stopService();
    } catch (e) {
      debugPrint('[CallTerminationService] stopService failed: $e');
    }

    try {
      ZegoUIKitPrebuiltCallController().minimize.hide();
    } catch (e) {
      debugPrint('[CallTerminationService] minimize.hide failed: $e');
    }
  }
}
