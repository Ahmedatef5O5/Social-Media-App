part of 'group_details_cubit.dart';

abstract class GroupDetailsState {}

class GroupDetailsInitial extends GroupDetailsState {}

class GroupDetailsLoading extends GroupDetailsState {}

class GroupDetailsLoaded extends GroupDetailsState {
  final List<GroupMessageModel> messages;
  final GroupPresenceSnapshot presence;
  final Map<String, double> uploadProgress;
  final bool isMember;
  GroupDetailsLoaded({
    required this.messages,
    this.presence = GroupPresenceSnapshot.empty,
    this.uploadProgress = const {},
    this.isMember = true,
  });
}

class GroupDetailsError extends GroupDetailsState {
  final String message;
  GroupDetailsError(this.message);
}
