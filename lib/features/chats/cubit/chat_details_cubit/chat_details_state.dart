part of 'chat_details_cubit.dart';

sealed class ChatDetailsState {
  const ChatDetailsState();
}

final class ChatDetailsInitial extends ChatDetailsState {}

final class ReceiverPresenceUpdated extends ChatDetailsState {
  final bool isOnline;
  final DateTime? lastSeen;
  const ReceiverPresenceUpdated({required this.isOnline, this.lastSeen});
}

final class MessagesLoading extends ChatDetailsState {}

final class MessagesSending extends ChatDetailsState {
  final List<MessageModel>? messages;
  final Map<String, double> uploadProgress;
  const MessagesSending({this.uploadProgress = const {}, this.messages});
}

final class MessagesSent extends ChatDetailsState {}

final class LastSeenUpdated extends ChatDetailsState {
  final DateTime? lastSeen;
  const LastSeenUpdated(this.lastSeen);
}

final class ReceiverTypingState extends ChatDetailsState {
  final bool isTyping;
  const ReceiverTypingState(this.isTyping);
}

final class MessagesSuccessLoaded extends ChatDetailsState {
  final List<MessageModel> messages;
  const MessagesSuccessLoaded({required this.messages});
}

final class MessagesError extends ChatDetailsState {
  final String message;
  const MessagesError(this.message);
}
