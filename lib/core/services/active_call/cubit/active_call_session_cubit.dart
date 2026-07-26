import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../active_call_session_data.dart';
import '../group_call_solo_watchdog.dart';

/// App-wide (registered once in `app.dart`, never disposed) source of truth
/// for "which call is currently connected and what should the persistent
/// header show for it".
///
/// Deliberately does **not** track "is it minimized" — that flag is owned
/// exclusively by
/// `ZegoUIKitPrebuiltCallController().minimize.isMinimizingNotifier`
/// (verified public API of `zego_uikit_prebuilt_call`). `ActiveCallHeaderWidget`
/// listens to both sources and only renders when both agree there is an
/// active + minimized call. This keeps a single source of truth for each
/// concern instead of duplicating/racing state.
class ActiveCallSessionCubit extends Cubit<ActiveCallSessionData?> {
  ActiveCallSessionCubit() : super(null);

  final GroupCallSoloWatchdog _soloWatchdog = GroupCallSoloWatchdog();

  /// Called once a 1:1 call becomes connected (`CallConnectedState`).
  void startSingleCallSession({
    required String callId,
    required String title,
    String? avatarUrl,
    required bool isVideo,
    required DateTime startedAt,
  }) {
    // A 1:1 session never needs the solo watchdog — stop any leftover one
    // defensively in case of an unexpected state transition.
    _soloWatchdog.stop();

    emit(
      ActiveCallSessionData(
        isGroup: false,
        callId: callId,
        title: title,
        avatarUrl: avatarUrl,
        isVideo: isVideo,
        startedAt: startedAt,
      ),
    );
  }

  /// Called once a group call becomes active (`GroupCallActive`).
  ///
  /// [onSoloTimeout] is invoked by the internal [GroupCallSoloWatchdog] when
  /// the local user has been alone in the room for a few seconds — pass in
  /// whatever "really end this call" callback the caller already has
  /// (typically `ZegoGroupCallView`'s own termination routine), the same
  /// callback used by the header's "End call" button end-state cleanup.
  void startGroupCallSession({
    required String callId,
    required String title,
    String? avatarUrl,
    required bool isVideo,
    required DateTime startedAt,
    required VoidCallback onSoloTimeout,
  }) {
    emit(
      ActiveCallSessionData(
        isGroup: true,
        callId: callId,
        title: title,
        avatarUrl: avatarUrl,
        isVideo: isVideo,
        startedAt: startedAt,
      ),
    );

    _soloWatchdog.start(onSoloTimeout: onSoloTimeout);
  }

  /// Call whenever the call has genuinely ended (not on minimize):
  /// - normal hangup from the full-screen view,
  /// - remote hangup,
  /// - the header's own "End call" button,
  /// - the solo watchdog's auto-termination.
  ///
  /// Idempotent — safe to call multiple times / from multiple listeners.
  void endSession() {
    _soloWatchdog.stop();
    if (state != null) {
      emit(null);
    }
  }

  bool get hasActiveSession => state != null;

  @override
  Future<void> close() {
    _soloWatchdog.stop();
    return super.close();
  }
}
