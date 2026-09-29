import 'package:livekit_client/livekit_client.dart';
import '../../../features/group_calls/services/group_call_signaling_service.dart';

/// Single source of truth for the "leave vs. end for everyone" decision on a
/// group call.
///
class GroupCallLeaveOrEndResolver {
  const GroupCallLeaveOrEndResolver._();

  static int liveParticipantCount(Room? room) {
    if (room == null) return 1;
    return room.remoteParticipants.length + 1;
  }

  static bool shouldEndCallForEveryone({
    required Room? room,
    required int? knownParticipantCount,
  }) {
    if (room != null && room.connectionState == ConnectionState.connected) {
      return room.remoteParticipants.length <= 1;
    }
    if (knownParticipantCount != null) {
      return knownParticipantCount <= 2;
    }
    return true;
  }

  static int remainingAfterLeave({
    required Room? room,
    required int? knownParticipantCount,
  }) {
    if (room != null && room.connectionState == ConnectionState.connected) {
      return room.remoteParticipants.length;
    }
    if (knownParticipantCount != null) {
      return (knownParticipantCount - 1).clamp(0, 1 << 30);
    }
    return 0;
  }

  static Future<void> signal({
    required int remainingAfterLeave,
    required GroupCallSignalingService signaling,
    required String callId,
    String? durationIfEnding,
  }) {
    final endForEveryone = remainingAfterLeave <= 1;

    if (endForEveryone) {
      return signaling.endCall(
        callId,
        duration: durationIfEnding,
        participantCount: remainingAfterLeave.clamp(0, 1 << 30),
      );
    }
    return signaling.leaveCall(callId);
  }
}
