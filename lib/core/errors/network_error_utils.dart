class NetworkErrorUtils {
  NetworkErrorUtils._();

  static bool isNetworkError(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('socketexception') ||
        msg.contains('clientexception') ||
        msg.contains('network') ||
        msg.contains('failed host lookup') ||
        msg.contains('connection refused') ||
        msg.contains('connection reset') ||
        msg.contains('connectionerror') ||
        msg.contains('fetch');
  }

  static bool isTimeoutError(Object e) {
    return e.toString().toLowerCase().contains('timeout');
  }
}
