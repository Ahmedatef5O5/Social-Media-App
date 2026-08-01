import '../models/groupe_message_model.dart';

class MediaDateSectioner {
  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static List<MapEntry<String, List<GroupMessageModel>>> bucket(
    List<GroupMessageModel> items,
  ) {
    final now = DateTime.now();
    final recentCutoff = now.subtract(const Duration(days: 3));
    final lastWeekCutoff = now.subtract(const Duration(days: 7));
    final lastMonthCutoff = now.subtract(const Duration(days: 30));

    final recent = <GroupMessageModel>[];
    final lastWeek = <GroupMessageModel>[];
    final lastMonth = <GroupMessageModel>[];
    final byMonth = <String, List<GroupMessageModel>>{};
    final monthOrder = <String>[];

    for (final item in items) {
      final date = item.createdAt.toLocal();
      if (date.isAfter(recentCutoff)) {
        recent.add(item);
      } else if (date.isAfter(lastWeekCutoff)) {
        lastWeek.add(item);
      } else if (date.isAfter(lastMonthCutoff)) {
        lastMonth.add(item);
      } else {
        final label = _monthLabel(date, now);
        if (!byMonth.containsKey(label)) {
          byMonth[label] = [];
          monthOrder.add(label);
        }
        byMonth[label]!.add(item);
      }
    }

    return [
      if (recent.isNotEmpty) MapEntry('Recent', recent),
      if (lastWeek.isNotEmpty) MapEntry('Last Week', lastWeek),
      if (lastMonth.isNotEmpty) MapEntry('Last Month', lastMonth),
      for (final label in monthOrder) MapEntry(label, byMonth[label]!),
    ];
  }

  static String _monthLabel(DateTime date, DateTime now) {
    final month = _monthNames[date.month - 1];
    return date.year == now.year ? month : '$month ${date.year}';
  }
}
