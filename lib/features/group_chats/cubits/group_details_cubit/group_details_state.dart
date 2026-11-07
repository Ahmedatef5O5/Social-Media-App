part of 'group_details_cubit.dart';

abstract class GroupDetailsState {}

class GroupDetailsInitial extends GroupDetailsState {}

class GroupDetailsLoading extends GroupDetailsState {}

class GroupDetailsLoaded extends GroupDetailsState {
  final List<GroupMessageModel> messages;
  final Map<String, double> uploadProgress;
  final bool isMember;

  /// False for an ACTIVE member the owner has restricted (who_can_send).
  final bool canSendMessages;
  final GroupWhoCanSend whoCanSend;
  GroupDetailsLoaded({
    required this.messages,
    this.uploadProgress = const {},
    this.isMember = true,
    this.canSendMessages = true,
    this.whoCanSend = GroupWhoCanSend.all,
  });
}

class GroupDetailsError extends GroupDetailsState {
  final String message;
  GroupDetailsError(this.message);
}
