enum AiReplyTone { standard, formal, enthusiastic, casual, encouraging }

extension AiReplyToneX on AiReplyTone {
  String get storageValue => name;

  String get wireValue {
    switch (this) {
      case AiReplyTone.standard:
        return 'standard';
      case AiReplyTone.formal:
        return 'formal';
      case AiReplyTone.enthusiastic:
        return 'enthusiastic';
      case AiReplyTone.casual:
        return 'casual';
      case AiReplyTone.encouraging:
        return 'encouraging';
    }
  }

  String get displayLabel {
    switch (this) {
      case AiReplyTone.standard:
        return 'Default';
      case AiReplyTone.formal:
        return 'Formal';
      case AiReplyTone.enthusiastic:
        return 'Enthusiastic';
      case AiReplyTone.casual:
        return 'Casual';
      case AiReplyTone.encouraging:
        return 'Encouraging';
    }
  }

  static AiReplyTone fromStorage(String? value) {
    return AiReplyTone.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AiReplyTone.standard,
    );
  }
}
