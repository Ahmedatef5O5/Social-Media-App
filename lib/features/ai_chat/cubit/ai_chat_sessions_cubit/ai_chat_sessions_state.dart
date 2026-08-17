part of 'ai_chat_sessions_cubit.dart';

sealed class AiChatSessionsState {}

class AiChatSessionsLoading extends AiChatSessionsState {}

class AiChatSessionsLoaded extends AiChatSessionsState {
  AiChatSessionsLoaded(this.sessions);
  final List<AiChatSession> sessions;
}

class AiChatSessionsError extends AiChatSessionsState {
  AiChatSessionsError(this.message);
  final String message;
}
