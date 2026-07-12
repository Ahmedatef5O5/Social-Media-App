import 'dart:ui';
import 'package:intl/intl.dart' show Bidi;

class ChatHelper {
  static bool isArabic(String text) {
    if (text.trim().isEmpty) return false;
    return Bidi.detectRtlDirectionality(text);
  }

  static TextDirection getTextDirection(String text) {
    return isArabic(text) ? TextDirection.rtl : TextDirection.ltr;
  }

  static String buildConversationId(String userA, String userB) {
    final sorted = [userA, userB]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }
}
