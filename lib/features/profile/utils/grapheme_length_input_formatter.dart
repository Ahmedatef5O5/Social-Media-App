import 'package:characters/characters.dart';
import 'package:flutter/services.dart';

class GraphemeLengthInputFormatter extends TextInputFormatter {
  GraphemeLengthInputFormatter(this.maxLength) : assert(maxLength > 0);

  final int maxLength;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newCharacters = newValue.text.characters;
    if (newCharacters.length <= maxLength) return newValue;

    final truncated = newCharacters.take(maxLength).toString();

    return TextEditingValue(
      text: truncated,
      selection: TextSelection.collapsed(offset: truncated.length),
    );
  }

  static int countCharacters(String text) => text.characters.length;
}
