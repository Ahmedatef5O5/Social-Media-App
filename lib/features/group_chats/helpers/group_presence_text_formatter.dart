import '../../../core/localization/app_l10n.dart';
import '../../../core/presence/models/chat_action_type.dart';
import '../models/group_presence_entry.dart';

typedef PresencePhrase = ({String text, ChatActionType action});

class GroupPresenceTextFormatter {
  static List<PresencePhrase> format(GroupPresenceSnapshot snapshot) {
    final List<PresencePhrase> phrases = [];

    for (final action in [ChatActionType.typing, ChatActionType.recording]) {
      final entries = snapshot.byAction[action] ?? const [];

      if (entries.isEmpty) continue;

      phrases.add((text: _phraseFor(action, entries), action: action));
    }

    return phrases;
  }

  static String _phraseFor(ChatActionType action, List entries) {
    final l10n = AppL10n.current;
    final count = entries.length;
    if (action == ChatActionType.typing) {
      if (count == 1) {
        return l10n.isTyping(entries.first.userName);
      }
      return l10n.peopleTyping(count);
    } else {
      if (count == 1) {
        return l10n.recordingAudio(entries.first.userName);
      }
      return l10n.peopleRecordingAudio(count);
    }
  }
}
