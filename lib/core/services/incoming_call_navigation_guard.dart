// Prevents the same incoming call (1:1 or group) from opening two
class IncomingCallNavigationGuard {
  IncomingCallNavigationGuard._();

  static final Set<String> _openCallIds = {};

  static bool claim(String callId) {
    if (callId.isEmpty) return true; // fail-open, never block navigation
    if (_openCallIds.contains(callId)) return false;
    _openCallIds.add(callId);
    return true;
  }

  static void release(String callId) {
    _openCallIds.remove(callId);
  }
}
