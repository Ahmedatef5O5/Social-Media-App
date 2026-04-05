import 'package:intl/intl.dart';

class FormattedDate {
  static String getFormattedDate(String dateString, {bool isShort = false}) {
    DateTime date = DateTime.parse(dateString);
    if (date.isUtc) {
      date = date.toLocal();
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
    final Duration exactDifference = now.difference(date);

    if (isShort) {
      if (exactDifference.isNegative) return 'Just now';
      if (exactDifference.inMinutes < 1) return 'now';
      if (exactDifference.inMinutes < 60) {
        return '${exactDifference.inMinutes} min';
      }
      if (exactDifference.inHours < 24) return '${exactDifference.inHours} hr';
      if (exactDifference.inDays < 7) return '${exactDifference.inDays} d';
      if (exactDifference.inDays < 30) {
        return '${(exactDifference.inDays / 7).floor()} w';
      }
      return DateFormat('d MMM').format(date);
    }

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
      final String dayMonth = DateFormat('d MMM').format(date);
      return "$dayMonth at $time";
    }
  }

  static String getChatTime(DateTime date, {bool isChatList = false}) {
    final DateTime localDate = date.toLocal();
    final DateTime now = DateTime.now();

    final String time = DateFormat.jm().format(localDate);
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime msgDate = DateTime(
      localDate.year,
      localDate.month,
      localDate.day,
    );
    final int diffInDays = today.difference(msgDate).inDays;

    if (diffInDays == 0) {
      return isChatList ? time : "Today";
    }

    if (diffInDays == 1) {
      return "Yesterday";
    }

    if (diffInDays < 7) {
      return DateFormat.EEEE().format(localDate);
    }

    if (isChatList) {
      return DateFormat('d MMMM').format(localDate);
    } else {
      if (localDate.year == now.year) {
        return DateFormat('d MMMM y').format(localDate);
      } else {
        return DateFormat('d MMMM y').format(localDate);
      }
    }
  }

  static String getLastSeen(DateTime lastSeen) {
    final lastSeenUtc = lastSeen.toUtc();
    final nowUtc = DateTime.now().toUtc();
    final diff = nowUtc.difference(lastSeenUtc);
    final String time = DateFormat.jm().format(lastSeenUtc);
    final String longTimeAgo = DateFormat('d/M/y').format(lastSeenUtc);
    if (diff.inSeconds < 30) return 'Online';
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return 'at ${diff.inMinutes} minutes ago';
    if (lastSeen.year == nowUtc.year &&
        lastSeen.month == nowUtc.month &&
        lastSeen.day == nowUtc.day) {
      return 'Today at $time';
    }
    final yesterday = nowUtc.subtract(const Duration(days: 1));
    if (lastSeen.year == yesterday.year &&
        lastSeen.month == yesterday.month &&
        lastSeen.day == yesterday.day) {
      return 'Yesterday at $time';
    }
    // if (diff.inDays == 1) return 'yesterday at $time';
    if (diff.inDays < 7) return 'at ${diff.inDays} days ago';
    return 'at $longTimeAgo';
  }

  static String getMessageTime(DateTime date) {
    return DateFormat.jm().format(date.toLocal());
  }
}
