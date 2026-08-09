import '../../../core/presence/model/chat_action_type.dart';

class GroupPresenceEntry {
  final String userId;
  final String userName;
  final String? userAvatar;
  final ChatActionType actionType;

  const GroupPresenceEntry({
    required this.userId,
    required this.userName,
    required this.actionType,
    this.userAvatar,
  });
}

class GroupPresenceSnapshot {
  final Map<ChatActionType, List<GroupPresenceEntry>> byAction;

  const GroupPresenceSnapshot(this.byAction);

  static const empty = GroupPresenceSnapshot({});

  bool get isEmpty => byAction.values.every((l) => l.isEmpty);

  List<GroupPresenceEntry> get typing =>
      byAction[ChatActionType.typing] ?? const [];
  List<GroupPresenceEntry> get recording =>
      byAction[ChatActionType.recording] ?? const [];

  int get activeActionCount =>
      byAction.values.where((l) => l.isNotEmpty).length;
}
