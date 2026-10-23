import 'package:flutter/widgets.dart';
import '../../../core/localization/l10n_extension.dart';

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

  String localizedTitle(BuildContext context) {
    switch (this) {
      case AiAutoCompleteLanguage.arabic:
        return context.l10n.aiLangArabicTitle;
      case AiAutoCompleteLanguage.english:
        return context.l10n.aiLangEnglishTitle;
      case AiAutoCompleteLanguage.auto:
        return context.l10n.aiLangAutoTitle;
    }
  }

  String localizedDescription(BuildContext context) {
    switch (this) {
      case AiAutoCompleteLanguage.arabic:
        return context.l10n.aiLangArabicDesc;
      case AiAutoCompleteLanguage.english:
        return context.l10n.aiLangEnglishDesc;
      case AiAutoCompleteLanguage.auto:
        return context.l10n.aiLangAutoDesc;
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
