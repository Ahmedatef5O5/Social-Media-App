import 'package:intl/intl.dart';
import '../models/shared_media_item.dart';
import '../../localization/app_l10n.dart';
import '../../localization/app_locale.dart';
import '../../../features/settings/repository/settings_repository.dart';

class SharedMediaDateSectioner {
  static List<MapEntry<String, List<SharedMediaItem>>> bucket(
    List<SharedMediaItem> items,
  ) {
    final now = DateTime.now();
    final recentCutoff = now.subtract(const Duration(days: 3));
    final lastWeekCutoff = now.subtract(const Duration(days: 7));
    final lastMonthCutoff = now.subtract(const Duration(days: 30));

    final recent = <SharedMediaItem>[];
    final lastWeek = <SharedMediaItem>[];
    final lastMonth = <SharedMediaItem>[];
    final byMonth = <String, List<SharedMediaItem>>{};
    final monthOrder = <String>[];

    final locale = AppLocale.normalize(
      SettingsRepository.instance.languageCode,
    );

    for (final item in items) {
      final date = item.createdAt.toLocal();
      if (date.isAfter(recentCutoff)) {
        recent.add(item);
      } else if (date.isAfter(lastWeekCutoff)) {
        lastWeek.add(item);
      } else if (date.isAfter(lastMonthCutoff)) {
        lastMonth.add(item);
      } else {
        final label = DateFormat('MMMM y', locale).format(date);
        if (!byMonth.containsKey(label)) {
          byMonth[label] = [];
          monthOrder.add(label);
        }
        byMonth[label]!.add(item);
      }
    }

    return [
      if (recent.isNotEmpty) MapEntry(AppL10n.current.sharedDateRecent, recent),
      if (lastWeek.isNotEmpty)
        MapEntry(AppL10n.current.sharedDateLastWeek, lastWeek),
      if (lastMonth.isNotEmpty)
        MapEntry(AppL10n.current.sharedDateLastMonth, lastMonth),
      for (final label in monthOrder) MapEntry(label, byMonth[label]!),
    ];
  }
}
