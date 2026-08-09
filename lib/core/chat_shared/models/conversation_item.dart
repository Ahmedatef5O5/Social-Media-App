import '../../../features/group_chats/models/group_model.dart';
import '../../../features/single_chats/models/chat_user_model.dart';
import 'conversation_flags.dart';
import 'conversation_ref.dart';

enum ConversationKind { single, group }

class ConversationItem {
  final ConversationKind kind;
  final ChatUserModel? chat;
  final GroupModel? group;
  final ConversationFlags flags;

  const ConversationItem._({
    required this.kind,
    this.chat,
    this.group,
    required this.flags,
  });

  factory ConversationItem.fromChat(
    ChatUserModel chat,
    ConversationFlags flags,
  ) => ConversationItem._(
    kind: ConversationKind.single,
    chat: chat,
    flags: flags,
  );

  factory ConversationItem.fromGroup(
    GroupModel group,
    ConversationFlags flags,
  ) => ConversationItem._(
    kind: ConversationKind.group,
    group: group,
    flags: flags,
  );

  ConversationRef get ref => ConversationRef(
    type:
        kind == ConversationKind.single
            ? ConversationType.single
            : ConversationType.group,
    id: kind == ConversationKind.single ? chat!.id : group!.id,
  );

  int get unreadCount =>
      kind == ConversationKind.single ? chat!.unreadCount : group!.unreadCount;

  DateTime? get lastActivityAt =>
      kind == ConversationKind.single
          ? chat!.lastMessageTime
          : (group!.lastMessageAt ?? group!.createdAt);

  bool get isMuted =>
      kind == ConversationKind.group
          ? group!.isMuted
          : (flags.muteOverride ?? flags.isArchived);

  bool get isPinned => flags.isPinned;
  bool get isFavorite => flags.isFavorite;
  bool get isArchived => flags.isArchived;
}
