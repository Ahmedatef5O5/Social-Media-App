import 'package:flutter/widgets.dart';

class BidiTextHelper {
  const BidiTextHelper._();

  static TextDirection detectDirection(String text) {
    for (final rune in text.runes) {
      if (_isRtl(rune)) return TextDirection.rtl;
      if (_isLtr(rune)) return TextDirection.ltr;
    }
    return TextDirection.ltr;
  }

  static TextAlign alignFor(TextDirection direction) =>
      direction == TextDirection.rtl ? TextAlign.right : TextAlign.left;

  static bool _isRtl(int rune) {
    return (rune >= 0x0591 && rune <= 0x05F4) || // Hebrew
        (rune >= 0x0600 && rune <= 0x06FF) || // Arabic
        (rune >= 0x0750 && rune <= 0x077F) || // Arabic Supplement
        (rune >= 0x08A0 && rune <= 0x08FF) || // Arabic Extended-A
        (rune >= 0xFB1D &&
            rune <= 0xFDFF) || // Hebrew/Arabic presentation forms A
        (rune >= 0xFE70 && rune <= 0xFEFF); // Arabic presentation forms B
  }

  static bool _isLtr(int rune) {
    return (rune >= 0x0041 && rune <= 0x005A) || // A-Z
        (rune >= 0x0061 && rune <= 0x007A) || // a-z
        (rune >= 0x00C0 && rune <= 0x024F) || // Latin Extended
        (rune >= 0x0370 && rune <= 0x03FF) || // Greek
        (rune >= 0x0400 && rune <= 0x04FF); // Cyrillic
  }
}
