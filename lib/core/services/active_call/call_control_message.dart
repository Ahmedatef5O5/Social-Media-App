import 'dart:convert';

/// Tiny reliable-data-channel protocol used to end calls instantly.

class CallControlMessage {
  const CallControlMessage(this.type, this.callId);

  static const String topic = 'call_control';
  static const String singleCallEnded = 'call_ended';
  static const String groupCallEnded = 'group_call_ended';

  final String type;
  final String? callId;

  static Map<String, dynamic> singleEnded(String callId) => {
    'type': singleCallEnded,
    'callId': callId,
  };

  static Map<String, dynamic> groupEnded(String callId) => {
    'type': groupCallEnded,
    'callId': callId,
  };

  static List<int> encode(Map<String, dynamic> payload) =>
      utf8.encode(jsonEncode(payload));

  /// Returns `null` for anything that is not a well-formed control message,
  /// so unrelated data packets can never end a call.
  static CallControlMessage? tryDecode(List<int> data) {
    try {
      final decoded = jsonDecode(utf8.decode(data));
      if (decoded is! Map) return null;
      final type = decoded['type'];
      if (type is! String) return null;
      final callId = decoded['callId'];
      return CallControlMessage(type, callId is String ? callId : null);
    } catch (_) {
      return null;
    }
  }

  /// `true` when this message ends [callId] of the given [expectedType].
  bool endsCall(String expectedType, String callId) =>
      type == expectedType && this.callId == callId;
}
