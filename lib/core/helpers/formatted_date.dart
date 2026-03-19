import 'package:intl/intl.dart';

class FormattedDate {
  static String getFormattedDate(String dateString) {
    DateTime date = DateTime.parse(dateString);
    if (date.isUtc) {
      date.toLocal().toIso8601String();
    }
    date = DateTime(
      date.year,
      date.month,
      date.day,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
    );

    final DateTime now = DateTime.now();

    //
    final Duration exactDifference = now.difference(date);

    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime storyDate = DateTime(date.year, date.month, date.day);
    final int diffInDays = today.difference(storyDate).inDays;

    final String time = DateFormat.jm().format(date);

    if (exactDifference.inMinutes < 1 && !exactDifference.isNegative) {
      return "Just now";
    }
    if (diffInDays == 0) {
      return "Today at $time";
    } else if (diffInDays == 1) {
      return "Yesterday at $time";
    } else {
      final String dayMonth = DateFormat.MMMd().format(date);
      return "$dayMonth at $time";
    }
  }
}
