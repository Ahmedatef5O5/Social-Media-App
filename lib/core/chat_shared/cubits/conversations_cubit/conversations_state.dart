part of 'conversations_cubit.dart';

enum ConversationTab { all, chats, groups, favorites, unread }

enum SelectionFlagState { allOn, allOff, mixed }

sealed class ConversationsState {
  const ConversationsState();
}

final class ConversationsInitial extends ConversationsState {
  const ConversationsInitial();
}

final class ConversationsLoaded extends ConversationsState {
  final List<ConversationItem> items;
  final List<ConversationItem> archivedItems;
  const ConversationsLoaded({required this.items, required this.archivedItems});
}
