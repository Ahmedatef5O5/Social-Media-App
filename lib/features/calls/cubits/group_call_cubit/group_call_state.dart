import '../../../group_chat/models/group_call_model.dart';

abstract class GroupCallState {}

class GroupCallInitial extends GroupCallState {}

class GroupCallRinging extends GroupCallState {
  final GroupCallModel call;
  GroupCallRinging(this.call);
}

class GroupCallIncoming extends GroupCallState {
  final GroupCallModel call;
  GroupCallIncoming(this.call);
}

class GroupCallOutgoing extends GroupCallState {
  final String groupId;
  final String groupName;
  final String? groupAvatarUrl;
  final GroupCallType type;
  final String initiatorName;

  GroupCallOutgoing({
    required this.groupId,
    required this.groupName,
    this.groupAvatarUrl,
    required this.type,
    required this.initiatorName,
  });
}

class GroupCallActive extends GroupCallState {
  final GroupCallModel call;
  GroupCallActive(this.call);
}

class GroupCallEnded extends GroupCallState {}

class GroupCallMissed extends GroupCallState {
  final GroupCallModel call;
  GroupCallMissed(this.call);
}

class GroupCallMissedByInitiator extends GroupCallState {}

class GroupCallError extends GroupCallState {
  final String message;
  GroupCallError(this.message);
}
