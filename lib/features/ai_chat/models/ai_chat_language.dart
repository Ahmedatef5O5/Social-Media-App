enum AiChatLanguage { auto, arabic, english }

extension AiChatLanguageWire on AiChatLanguage {
  String get wireValue {
    switch (this) {
      case AiChatLanguage.arabic:
        return 'ar';
      case AiChatLanguage.english:
        return 'en';
      case AiChatLanguage.auto:
        return 'auto';
    }
  }
}
