import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../notifications/notification_navigator_key.dart';
import 'active_call/cubits/active_call_session_cubit.dart';

class IncomingCallNavigationGuard {
  IncomingCallNavigationGuard._();

  static final Set<String> _openCallIds = {};
  static final Set<String> _locallyInitiatedCallIds = <String>{};
  static bool _isOutgoingGroupCallActive = false;
  static const int _maxLocallyInitiated = 64;

  static bool claim(String callId) {
    if (callId.isEmpty) return true; // fail-open, never block navigation
    if (_openCallIds.contains(callId)) return false;
    _openCallIds.add(callId);
    return true;
  }

  static void release(String callId) {
    _openCallIds.remove(callId);
  }

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

  static void setOutgoingGroupCallActive(bool active) {
    _isOutgoingGroupCallActive = active;
  }

  static bool get isOutgoingGroupCallActive => _isOutgoingGroupCallActive;

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
    if (_hasActiveCallSession()) return true;
    return false;
  }

  static bool _hasActiveCallSession() {
    final context = navigatorKey.currentContext;
    if (context == null) return false;
    try {
      return context.read<ActiveCallSessionCubit>().state != null;
    } catch (_) {
      // Provider not in scope (very early startup / tests): fail open.
      return false;
    }
  }

  @visibleForTesting
  static void resetForTest() {
    _openCallIds.clear();
    _locallyInitiatedCallIds.clear();
    _isOutgoingGroupCallActive = false;
  }
}
