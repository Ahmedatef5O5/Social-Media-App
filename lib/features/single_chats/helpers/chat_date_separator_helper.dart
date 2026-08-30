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

  static bool isLastInSenderCluster<T>({
    required List<T> messages,
    required int index,
    required String Function(T) getSenderId,
    required DateTime Function(T) getCreatedAt,
  }) {
    if (index == 0) return true;

    final current = messages[index];
    final below = messages[index - 1];

    if (getSenderId(below) != getSenderId(current)) return true;

    final currentLocal = getCreatedAt(current).toLocal();
    final belowLocal = getCreatedAt(below).toLocal();

    if (!isSameDay(currentLocal, belowLocal)) return true;

    return false;
  }
}
