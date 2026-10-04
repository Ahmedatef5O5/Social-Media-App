import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/single_calls/cubits/single_call_cubit/call_cubit.dart';
import '../notifications/notification_navigator_key.dart';
import 'active_call/cubits/active_call_session_cubit.dart';
import 'active_call/pip/call_pip_cubit.dart';

/// Prevents the same incoming call (1:1 or group) from opening two screens,
/// guarantees the INITIATOR is never shown an incoming-call screen for a call
/// they started themselves, and — new — guarantees that a user who is already
/// in (or dialing / ringing into) a call is never disturbed by another one.
class IncomingCallNavigationGuard {
  IncomingCallNavigationGuard._();

  // Call ids whose screen is open / already handled. (Spec name:
  // `_activeOrHandledCallIds`; the field keeps its original name so no
  // existing caller changes.)
  static final Set<String> _openCallIds = {};

  // Call ids THIS device created. Held while the call is alive so a stale
  // realtime/FCM echo of our own call stays blocked; released explicitly via
  // [clearLocalInitiation] once the local user leaves/ends the call.
  static final Set<String> _locallyInitiatedCallIds = <String>{};

  static bool _isOutgoingGroupCallActive = false;

  static const int _maxLocallyInitiated = 64;

  // ── Synchronous "I am busy" registry ────────────────────────────────────
  //
  // Written by `ActiveCallSessionCubit` (connected 1:1 / group session) and by
  // `CallCubit` (dialing / connected 1:1). Kept independent of the widget tree
  // so the answer is correct even when `navigatorKey.currentContext` is null
  // or a provider is not yet in scope.
  static String? _activeSessionCallId;
  static String? _singleCallInProgressId;

  // ── Cross-isolate mirror ────────────────────────────────────────────────
  //
  // `firebaseMessagingBackgroundHandler` runs in a SEPARATE isolate, where the
  // statics above are empty. The main isolate therefore mirrors "which call am
  // I busy with" into SharedPreferences so that isolate can also refuse to
  // ring while a call is in progress.
  static const String _kBusyCallId = 'incoming_guard_busy_call_id';
  static const String _kBusyAtMs = 'incoming_guard_busy_at_ms';

  // Safety net for a flag left behind by a crash / force-stop.
  static const Duration _persistedBusyMaxAge = Duration(hours: 4);

  static bool claim(String callId) {
    if (callId.isEmpty) return true; // fail-open, never block navigation
    if (_openCallIds.contains(callId)) return false;
    _openCallIds.add(callId);
    return true;
  }

  static void release(String callId) {
    _openCallIds.remove(callId);
  }

  /// Registers [callId] as created by this device. Call it BEFORE the
  /// `group_calls` row is inserted so there is no window in which the
  /// initiator's own realtime/FCM echo can slip through.
  static void markLocallyInitiated(String callId) {
    if (callId.isEmpty) return;
    _locallyInitiatedCallIds.add(callId);
    _openCallIds.add(callId);

    while (_locallyInitiatedCallIds.length > _maxLocallyInitiated) {
      final oldest = _locallyInitiatedCallIds.first;
      _locallyInitiatedCallIds.remove(oldest);
      _openCallIds.remove(oldest);
    }
  }

  /// Releases the "this device created the call" marker for [callId].
  ///
  /// Called when the local user LEAVES or ENDS a call. Without it, an
  /// initiator who left a 3+ person call could never be rung back into it by
  /// another member: the stale marker made every incoming ring for that call
  /// id look like an echo of their own call.
  static void clearLocalInitiation(String callId) {
    if (callId.isEmpty) return;
    _locallyInitiatedCallIds.remove(callId);
    _openCallIds.remove(callId);
  }

  /// `true` from just before `initiateCall` until the outgoing screen is
  /// disposed. While set, NO incoming group-call screen may open.
  static void setOutgoingGroupCallActive(bool active) {
    _isOutgoingGroupCallActive = active;
  }

  static bool get isOutgoingGroupCallActive => _isOutgoingGroupCallActive;

  /// Called by `ActiveCallSessionCubit` whenever a session starts (`callId`)
  /// or ends (`null`).
  static void setActiveCallSession(String? callId) {
    _activeSessionCallId = (callId == null || callId.isEmpty) ? null : callId;
    _persistBusyState();
  }

  /// Called by `CallCubit` when a 1:1 call is dialing / connected (`callId`)
  /// or over (`null`). A merely RINGING incoming call is deliberately not
  /// registered here: an unanswered ring must never make the user "busy".
  static void setSingleCallInProgress(String? callId) {
    _singleCallInProgressId =
        (callId == null || callId.isEmpty) ? null : callId;
    _persistBusyState();
  }

  static String? get activeSessionCallId => _activeSessionCallId;

  /// `true` when the user is already in, dialing, or ringing into a call whose
  /// id differs from [incomingCallId] (1:1 or group).
  ///
  /// Pass `null` / empty to ask "is the user busy with ANY call".
  static bool isUserBusyWithAnotherCall([String? incomingCallId]) {
    final incoming = incomingCallId ?? '';
    bool differs(String? activeId) =>
        activeId != null && activeId.isNotEmpty && activeId != incoming;

    if (differs(_activeSessionCallId)) return true;
    if (differs(_singleCallInProgressId)) return true;

    // Our own outgoing group call (ringing screen) counts as busy for anything
    // that is not that very call.
    if (_isOutgoingGroupCallActive &&
        !_locallyInitiatedCallIds.contains(incoming)) {
      return true;
    }

    final context = navigatorKey.currentContext;
    if (context == null) return false;

    try {
      final session = context.read<ActiveCallSessionCubit>().state;
      if (differs(session?.callId)) return true;

      // A live LiveKit room with no session yet (connect in progress) is
      // still a call in progress.
      final pip = context.read<CallPipCubit>();
      if (pip.hasActiveRoom && session == null) return true;

      final callCubit = context.read<CallCubit>();
      if (callCubit.isBusy) {
        final activeId = callCubit.activeCallId;
        if (activeId == null || differs(activeId)) return true;
      }
    } catch (_) {
      // Provider not in scope (very early startup / tests): fall back to the
      // static registry above, which already answered `false`.
    }
    return false;
  }

  /// Like [isUserBusyWithAnotherCall] but ALSO consults the mirror written by
  /// the main isolate, so it is correct inside the FCM background isolate.
  static Future<bool> isUserBusyAcrossIsolates([String? incomingCallId]) async {
    if (isUserBusyWithAnotherCall(incomingCallId)) return true;

    try {
      final prefs = await SharedPreferences.getInstance();
      // Another isolate wrote the value: refresh this isolate's cache first.
      await prefs.reload();
      final busyId = prefs.getString(_kBusyCallId);
      if (busyId == null || busyId.isEmpty) return false;

      final atMs = prefs.getInt(_kBusyAtMs) ?? 0;
      final age = DateTime.now().millisecondsSinceEpoch - atMs;
      if (atMs == 0 || age > _persistedBusyMaxAge.inMilliseconds) return false;

      return busyId != (incomingCallId ?? '');
    } catch (e) {
      debugPrint('[IncomingCallGuard] persisted busy lookup failed: $e');
      return false;
    }
  }

  /// A fresh main isolate means no call can be alive (the LiveKit room dies
  /// with the process), so any mirrored flag is stale. Called from bootstrap.
  static Future<void> clearPersistedBusyState() async {
    _activeSessionCallId = null;
    _singleCallInProgressId = null;
    await _writePersisted(null);
  }

  static void _persistBusyState() {
    final busyId = _activeSessionCallId ?? _singleCallInProgressId;
    _writePersisted(busyId);
  }

  static Future<void> _writePersisted(String? busyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (busyId == null) {
        await prefs.remove(_kBusyCallId);
        await prefs.remove(_kBusyAtMs);
      } else {
        await prefs.setString(_kBusyCallId, busyId);
        await prefs.setInt(_kBusyAtMs, DateTime.now().millisecondsSinceEpoch);
      }
    } catch (e) {
      debugPrint('[IncomingCallGuard] persisting busy state failed: $e');
    }
  }

  /// Single decision point for every path that can open
  /// `IncomingGroupCallScreen` (FCM foreground, notification tap, global
  /// realtime listener). Returns `true` to BLOCK the screen.
  static bool shouldBlockIncomingGroupCall({
    required String callId,
    required String initiatorId,
    required String? currentUserId,
  }) {
    if (currentUserId == null) return true;
    if (initiatorId.isNotEmpty && initiatorId == currentUserId) return true;
    if (callId.isNotEmpty && _locallyInitiatedCallIds.contains(callId)) {
      return true;
    }
    if (_isOutgoingGroupCallActive) return true;
    if (callId.isNotEmpty && _openCallIds.contains(callId)) return true;
    if (isUserBusyWithAnotherCall(callId)) return true;
    return false;
  }

  /// Single decision point for an incoming 1:1 call. `true` == BLOCK it.
  static bool shouldBlockIncomingSingleCall(String callId) =>
      isUserBusyWithAnotherCall(callId);

  @visibleForTesting
  static void resetForTest() {
    _openCallIds.clear();
    _locallyInitiatedCallIds.clear();
    _isOutgoingGroupCallActive = false;
    _activeSessionCallId = null;
    _singleCallInProgressId = null;
  }
}
