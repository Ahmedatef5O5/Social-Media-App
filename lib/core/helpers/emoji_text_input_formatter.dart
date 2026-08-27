import 'package:flutter/services.dart';
import 'emoji_helper.dart';

class EmojiTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final normalized = EmojiHelper.normalize(newValue.text);
    if (normalized == newValue.text) return newValue;

    int countAddedBefore(int offset) {
      if (offset < 0 || offset > newValue.text.length) return 0;
      final String before = newValue.text.substring(0, offset);
      final String normalizedBefore = EmojiHelper.normalize(before);
      return normalizedBefore.length - before.length;
    }

    int newBase = newValue.selection.baseOffset;
    int newExtent = newValue.selection.extentOffset;

    if (newValue.selection.isValid) {
      newBase += countAddedBefore(newBase);
      newExtent += countAddedBefore(newExtent);
    }

    return newValue.copyWith(
      text: normalized,
      selection: newValue.selection.copyWith(
        baseOffset: newBase,
        extentOffset: newExtent,
      ),
      composing: TextRange.empty,
    );
  }
}
