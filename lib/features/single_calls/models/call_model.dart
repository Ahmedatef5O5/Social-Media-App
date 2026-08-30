enum CallStatus { dialing, ringing, accepted, rejected, ended, busy }

enum CallType { audio, video }

class CallModel {
  final String callId;
  final String callerId;
  final String callerName;
  final String callerAvatar;
  final String receiverId;
  final String receiverName;
  final String receiverAvatar;
  final CallStatus status;
  final CallType type;
  final DateTime? startTime;

  CallModel({
    required this.callId,
    required this.callerId,
    required this.callerName,
    required this.callerAvatar,
    required this.receiverId,
    required this.receiverName,
    required this.receiverAvatar,
    required this.status,
    required this.type,
    this.startTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'call_id': callId,
      'caller_id': callerId,
      'caller_name': callerName,
      'caller_avatar': callerAvatar,
      'receiver_id': receiverId,
      'receiver_name': receiverName,
      'receiver_avatar': receiverAvatar,
      'status': status.name,
      'type': type.name,
      'start_time': startTime?.toIso8601String(),
    };
  }

  factory CallModel.fromMap(Map<String, dynamic> map) {
    return CallModel(
      callId: map['call_id'],
      callerId: map['caller_id'],
      callerName: map['caller_name'],
      callerAvatar: map['caller_avatar'],
      receiverId: map['receiver_id'],
      receiverName: map['receiver_name'],
      receiverAvatar: map['receiver_avatar'],
      status: CallStatus.values.byName(map['status']),
      type: CallType.values.byName(map['type']),
      startTime:
          map['start_time'] != null ? DateTime.parse(map['start_time']) : null,
    );
  }
}
