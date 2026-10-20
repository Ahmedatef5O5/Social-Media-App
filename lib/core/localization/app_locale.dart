import 'package:flutter/widgets.dart';

/// Single source of truth for the languages the app ships with.
///
/// UI direction follows the active [Locale] (via `Localizations`), while the
/// direction of user-generated text stays owned by `BidiTextHelper`.
abstract final class AppLocale {
  static const String english = 'en';
  static const String arabic = 'ar';
  static const String defaultCode = english;

  static const List<String> supportedCodes = <String>[english, arabic];
  static const List<Locale> supportedLocales = <Locale>[
    Locale(english),
    Locale(arabic),
  ];

  /// Maps anything (null, "AR", "ar_EG", "fr") to a supported code.
  static String normalize(String? code) {
    if (code == null) return defaultCode;
    final primary = code.trim().toLowerCase().split(RegExp(r'[-_]')).first;
    return supportedCodes.contains(primary) ? primary : defaultCode;
  }

  static Locale toLocale(String? code) => Locale(normalize(code));

  static bool isArabic(String? code) => normalize(code) == arabic;
}
