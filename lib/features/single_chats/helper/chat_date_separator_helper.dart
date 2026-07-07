class ChatDateSeparatorHelper {
  static bool shouldShowDate<T>({
    required List<T> messages,
    required int index,
    required DateTime Function(T) getCreatedAt,
  }) {
    if (index == messages.length - 1) return true;

    final current = getCreatedAt(messages[index]).toLocal();
    final olderMessage = getCreatedAt(messages[index + 1]).toLocal();

    return !isSameDay(current, olderMessage);
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
