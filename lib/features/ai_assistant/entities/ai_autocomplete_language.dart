enum AiAutoCompleteLanguage { arabic, english, auto }

extension AiAutoCompleteLanguageX on AiAutoCompleteLanguage {
  String get storageValue => name;

  String get wireValue {
    switch (this) {
      case AiAutoCompleteLanguage.arabic:
        return 'ar';
      case AiAutoCompleteLanguage.english:
        return 'en';
      case AiAutoCompleteLanguage.auto:
        return 'auto';
    }
  }

  String get displayLabel {
    switch (this) {
      case AiAutoCompleteLanguage.arabic:
        return 'Arabic';
      case AiAutoCompleteLanguage.english:
        return 'English';
      case AiAutoCompleteLanguage.auto:
        return 'Auto (Based on Context)';
    }
  }

  static AiAutoCompleteLanguage fromStorage(String? value) {
    return AiAutoCompleteLanguage.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AiAutoCompleteLanguage.auto,
    );
  }
}
