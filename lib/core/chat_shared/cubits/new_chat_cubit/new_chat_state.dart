part of 'new_chat_cubit.dart';

sealed class NewChatState {
  const NewChatState();
}

final class NewChatInitial extends NewChatState {}

final class NewChatLoading extends NewChatState {}

final class NewChatLoaded extends NewChatState {
  final List<NewChatRow> rows;
  final String query;

  const NewChatLoaded({required this.rows, this.query = ''});
}

final class NewChatError extends NewChatState {
  final String message;
  const NewChatError(this.message);
}
