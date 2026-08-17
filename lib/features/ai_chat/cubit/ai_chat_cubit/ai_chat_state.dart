part of 'ai_chat_cubit.dart';

sealed class AiChatMessagesState {}

class AiChatMessagesLoading extends AiChatMessagesState {}

class AiChatMessagesLoaded extends AiChatMessagesState {
  final List<AiChatMessage> messages;
  final bool isSending;
  final String? error;

  AiChatMessagesLoaded({
    required this.messages,
    required this.isSending,
    this.error,
  });
}

class AiChatMessagesError extends AiChatMessagesState {
  AiChatMessagesError(this.message);
  final String message;
}
