import 'dart:ui';

class ChatHelper {
  static bool isArabic(String text) {
    if (text.trim().isEmpty) return false;
    final firstCharUnit = text.trim().codeUnitAt(0);
    return firstCharUnit >= 0x0600 && firstCharUnit <= 0x06FF;
  }

  static TextDirection getTextDirection(String text) {
    return isArabic(text) ? TextDirection.rtl : TextDirection.ltr;
  }

  static String buildConversationId(String userA, String userB) {
    final sorted = [userA, userB]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }
}
