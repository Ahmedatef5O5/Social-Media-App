enum AiReplyLength { standard, short, detailed }

extension AiReplyLengthX on AiReplyLength {
  String get storageValue => name;

  String get wireValue {
    switch (this) {
      case AiReplyLength.standard:
        return 'standard';
      case AiReplyLength.short:
        return 'short';
      case AiReplyLength.detailed:
        return 'detailed';
    }
  }

  String get displayLabel {
    switch (this) {
      case AiReplyLength.standard:
        return 'Default';
      case AiReplyLength.short:
        return 'Short & Concise';
      case AiReplyLength.detailed:
        return 'Detailed';
    }
  }

  static AiReplyLength fromStorage(String? value) {
    return AiReplyLength.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AiReplyLength.standard,
    );
  }
}
