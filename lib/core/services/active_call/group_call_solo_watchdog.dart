import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:zego_uikit/zego_uikit.dart';

/// Watches the live participant count of the current Zego room and invokes
/// [onSoloTimeout] once the local user has been alone in the call for
/// [grace] seconds.
///
/// This logic used to live inside `_ZegoGroupCallViewState` (tied to that
/// screen's `initState`/`dispose`). That was fine as long as the call view
/// stayed on the navigation stack, but `ZegoUIKitPrebuiltCallController()
/// .minimize.minimize()` calls `Navigator.pop()` on that exact screen, which
/// disposes it — silently killing this safety net the moment a group call is
/// minimized.
///
/// By moving it here and owning the instance from [ActiveCallSessionCubit]
/// (an app-lifetime singleton), the watchdog now survives minimize/restore
/// cycles and only stops when the call session truly ends.
class GroupCallSoloWatchdog {
  StreamSubscription<List<ZegoUIKitUser>>? _liveUsersSub;
  Timer? _graceTimer;
  bool _callHasStarted = false;
  bool _hasTriggered = false;

  /// Starts watching. Safe to call even if a previous watch is still
  /// running — it will be stopped and replaced.
  void start({
    required VoidCallback onSoloTimeout,
    Duration grace = const Duration(seconds: 3),
  }) {
    stop();
    _hasTriggered = false;

    // Evaluate immediately with whoever is already in the room.
    _evaluate(ZegoUIKit().getAllUsers(), onSoloTimeout, grace);

    _liveUsersSub = ZegoUIKit().getUserListStream().listen(
      (users) => _evaluate(users, onSoloTimeout, grace),
    );
  }

  void _evaluate(
    List<ZegoUIKitUser> users,
    VoidCallback onSoloTimeout,
    Duration grace,
  ) {
    if (_hasTriggered) return;

    final count = users.length;

    if (count >= 2) {
      _callHasStarted = true;
      _graceTimer?.cancel();
      _graceTimer = null;
      return;
    }

    // Only terminate after the call actually had 2+ people at some point,
    // and give a short grace period in case of a brief reconnect blip.
    if (_callHasStarted && count < 2) {
      _graceTimer ??= Timer(grace, () {
        _hasTriggered = true;
        onSoloTimeout();
      });
    }
  }

  /// Stops watching and resets internal state. Must be called when the call
  /// session truly ends (not on minimize).
  void stop() {
    _liveUsersSub?.cancel();
    _liveUsersSub = null;
    _graceTimer?.cancel();
    _graceTimer = null;
    _callHasStarted = false;
  }
}
