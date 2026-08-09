enum ChatActionType { none, typing, recording }

extension ChatActionTypeX on ChatActionType {
  String get value => switch (this) {
    ChatActionType.none => 'none',
    ChatActionType.typing => 'typing',
    ChatActionType.recording => 'recording',
  };

  static ChatActionType fromValue(String? raw) => switch (raw) {
    'typing' => ChatActionType.typing,
    'recording' => ChatActionType.recording,
    _ => ChatActionType.none,
  };
}
