import 'package:collection/collection.dart';
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupPresenceEntry &&
          userId == other.userId &&
          userName == other.userName &&
          userAvatar == other.userAvatar &&
          actionType == other.actionType);

  @override
  int get hashCode => Object.hash(userId, userName, userAvatar, actionType);
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

  static const _mapEquality =
      MapEquality<ChatActionType, List<GroupPresenceEntry>>(
        values: ListEquality<GroupPresenceEntry>(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupPresenceSnapshot &&
          _mapEquality.equals(byAction, other.byAction));

  @override
  int get hashCode => _mapEquality.hash(byAction);
}
