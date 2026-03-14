import 'package:intl/intl.dart';

class FormattedDate {
  static String getFormattedDate(String dateString) {
    final DateTime date = DateTime.parse(dateString);
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime storyDate = DateTime(date.year, date.month, date.day);
    final int diffInDays = today.difference(storyDate).inDays;
    final String time = DateFormat.jm().format(date);

    if (diffInDays == 0) {
      return "Today at $time";
    } else if (diffInDays == 1) {
      return "Yesterday at $time";
    } else {
      final String dayMonth = DateFormat.MMMd().format(date);
      return "$dayMonth at $time";
    }
  }

  // static String getTimeAgo(DateTime date) {
  //   final Duration diff = DateTime.now().difference(date);

  //   if (diff.inDays > 365) {
  //     return "${(diff.inDays / 365).floor()}y ago";
  //   } else if (diff.inDays > 30) {
  //     return "${(diff.inDays / 30).floor()}mo ago";
  //   } else if (diff.inDays > 2) {
  //     return "${diff.inDays}d ago";
  //   } else if (diff.inDays > 1) {
  //     return "Yesterday";
  //   } else if (diff.inHours > 0) {
  //     return "${diff.inHours}h ago";
  //   } else if (diff.inMinutes > 0) {
  //     return "${diff.inMinutes}m ago";
  //   } else {
  //     return "just now";
  //   }
  // }
}
