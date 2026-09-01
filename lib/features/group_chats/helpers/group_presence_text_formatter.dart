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
    final verb =
        action == ChatActionType.typing ? 'is typing...' : 'recording audio...';

    if (entries.length == 1) {
      return '${entries.first.userName} $verb';
    }

    final noun = action == ChatActionType.typing ? 'typing' : 'recording audio';

    return '${entries.length} people are $noun...';
  }
}
