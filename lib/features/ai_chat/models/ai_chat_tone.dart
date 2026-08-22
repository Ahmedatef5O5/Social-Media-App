enum AiChatTone { standard, formal, enthusiastic, casual, encouraging }

extension AiChatToneWire on AiChatTone {
  String get wireValue {
    switch (this) {
      case AiChatTone.standard:
        return 'standard';
      case AiChatTone.formal:
        return 'formal';
      case AiChatTone.enthusiastic:
        return 'enthusiastic';
      case AiChatTone.casual:
        return 'casual';
      case AiChatTone.encouraging:
        return 'encouraging';
    }
  }
}
