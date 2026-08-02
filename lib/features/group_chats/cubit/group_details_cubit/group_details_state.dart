part of 'group_details_cubit.dart';

abstract class GroupDetailsState {}

class GroupDetailsInitial extends GroupDetailsState {}

class GroupDetailsLoading extends GroupDetailsState {}

class GroupDetailsLoaded extends GroupDetailsState {
  final List<GroupMessageModel> messages;
  final List<String> typingUserIds;
  final Map<String, double> uploadProgress;
  final bool isMember;
  GroupDetailsLoaded({
    required this.messages,
    this.typingUserIds = const [],
    this.uploadProgress = const {},
    this.isMember = true,
  });
}

class GroupDetailsError extends GroupDetailsState {
  final String message;
  GroupDetailsError(this.message);
}
