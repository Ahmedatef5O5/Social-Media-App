part of 'chat_details_cubit.dart';

sealed class ChatDetailsState {
  const ChatDetailsState();
}

final class ChatDetailsInitial extends ChatDetailsState {}

final class MessagesLoading extends ChatDetailsState {}

final class MessagesSending extends ChatDetailsState {
  final List<MessageModel>? messages;

  MessagesSending({this.messages});
}

final class MessagesSent extends ChatDetailsState {}

final class LastSeenUpdated extends ChatDetailsState {
  final DateTime? lastSeen;
  const LastSeenUpdated(this.lastSeen);
}

final class MessagesSuccessLoaded extends ChatDetailsState {
  final List<MessageModel> messages;
  const MessagesSuccessLoaded({required this.messages});
}

final class MessagesError extends ChatDetailsState {
  final String message;
  const MessagesError(this.message);
}
