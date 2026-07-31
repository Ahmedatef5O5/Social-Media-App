import '../models/groupe_message_model.dart';

class GroupSystemEventTextBuilder {
  static String build({
    required GroupMessageModel message,
    required String currentUserId,
  }) {
    final data = message.systemEventData;
    if (data == null) return message.text;

    final type = data['type'] as String?;
    final actorId = data['actor_id'] as String?;
    final actorName = data['actor_name'] as String? ?? 'Someone';
    final targetId = data['target_id'] as String?;
    final targetName = data['target_name'] as String?;

    final actor = actorId == currentUserId ? 'You' : actorName;
    final target = targetId == currentUserId ? 'you' : (targetName ?? '');

    switch (type) {
      case 'member_added':
        return '$actor added $target';
      case 'member_removed':
        return '$actor removed $target';
      case 'member_left':
        return '$actor left the group';
      default:
        return message.text;
    }
  }
}
