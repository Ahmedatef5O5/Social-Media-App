part of 'chats_cubit.dart';

sealed class ChatsState {
  const ChatsState();
}

final class ChatsInitial extends ChatsState {}

class ChatsRefreshFeedback extends ChatsState {}

final class ChatsLoading extends ChatsState {}

final class ChatsSuccessloaded extends ChatsState {
  final List<ChatUserModel> chats;
  const ChatsSuccessloaded({required this.chats});
}

final class ChatsError extends ChatsState {
  final String message;
  const ChatsError(this.message);
}
