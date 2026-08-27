import 'package:flutter/material.dart';

class EmojiHelper {
  EmojiHelper._();

  static final RegExp _emojiNormalizationRegex = RegExp(
    r'([\u2764\u2665\u260E\u263A\u2639\u270C\u270A\u270B\u261D\u26A0\u2728\u2B50\u2705\u274C\u26A1\u26BD\u2702\u2709\u270F\u2714\u2716\u2757\u2753\u2763\u2615\u267B])(?!\uFE0F|\uFE0E)',
  );

  static String normalize(String text) {
    if (text.isEmpty) return text;
    return text.replaceAllMapped(
      _emojiNormalizationRegex,
      (match) => '${match[1]}\uFE0F',
    );
  }

  static TextStyle getStyle({
    TextStyle? baseStyle,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
  }) {
    return (baseStyle ?? const TextStyle()).copyWith(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
    );
  }
}
