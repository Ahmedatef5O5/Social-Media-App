import 'package:flutter/services.dart';

class AppFormatters {
  static List<TextInputFormatter> noSpaces = [
    FilteringTextInputFormatter.deny(RegExp(r'\s')),
  ];

  static List<TextInputFormatter> noLeadingSpace = [
    FilteringTextInputFormatter.deny(RegExp(r'^\s')),
    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Zأ-ي\s]')),
    TextInputFormatter.withFunction((oldValue, newValue) {
      if (newValue.text.contains('  ')) {
        return oldValue;
      }
      return newValue;
    }),
  ];
}
