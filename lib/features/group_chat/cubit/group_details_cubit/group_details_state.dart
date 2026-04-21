import '../../models/groupe_message_model.dart';

abstract class GroupDetailsState {}

class GroupDetailsInitial extends GroupDetailsState {}

class GroupDetailsLoading extends GroupDetailsState {}

class GroupDetailsLoaded extends GroupDetailsState {
  final List<GroupMessageModel> messages;
  final List<String> typingUserIds;
  final Map<String, double> uploadProgress;
  GroupDetailsLoaded({
    required this.messages,
    this.typingUserIds = const [],
    this.uploadProgress = const {},
  });
}

class GroupDetailsError extends GroupDetailsState {
  final String message;
  GroupDetailsError(this.message);
}
