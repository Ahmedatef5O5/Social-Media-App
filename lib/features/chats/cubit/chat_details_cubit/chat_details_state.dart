part of 'chat_details_cubit.dart';

sealed class ChatDetailsState {
  const ChatDetailsState();
}

final class ChatDetailsInitial extends ChatDetailsState {}

final class MessagesLoading extends ChatDetailsState {}

final class MessagesSuccessLoaded extends ChatDetailsState {
  final List<MessageModel> messages;
  const MessagesSuccessLoaded({required this.messages});
}

final class MessagesError extends ChatDetailsState {
  final String message;
  const MessagesError(this.message);
}
