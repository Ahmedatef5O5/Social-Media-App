import '../models/groupe_message_model.dart';
import 'package:social_media_app/core/localization/app_l10n.dart';

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

    final actor = actorId == currentUserId ? AppL10n.current.you : actorName;
    final target = targetId == currentUserId ? 'you' : (targetName ?? '');

    switch (type) {
      case 'member_added':
        return AppL10n.current.added(actor, target);
      case 'member_removed':
        return AppL10n.current.removed(actor, target);
      case 'member_left':
        return AppL10n.current.leftTheGroup(actor);
      default:
        return message.text;
    }
  }
}
