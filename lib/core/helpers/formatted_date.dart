import 'package:intl/intl.dart';
import 'package:social_media_app/core/localization/app_l10n.dart';
import '../../features/settings/repository/settings_repository.dart';
import '../localization/app_locale.dart';

class FormattedDate {
  static DateTime safeParseDate(String dateString) {
    final date = DateTime.parse(dateString);

    return date.isUtc ? date.toLocal() : date;
  }

  static String getFormattedDate(String dateString, {bool isShort = false}) {
    final DateTime date = safeParseDate(dateString);
    final DateTime now = DateTime.now();
    final Duration exactDifference = now.difference(date);

    final locale = AppLocale.normalize(
      SettingsRepository.instance.languageCode,
    );
    final isAr = locale.startsWith('ar');

    if (isShort) {
      if (exactDifference.isNegative) return AppL10n.current.justNow;
      if (exactDifference.inMinutes < 1) return isAr ? 'الآن' : 'now';
      if (exactDifference.inMinutes < 60) {
        return AppL10n.current.min(exactDifference.inMinutes);
      }
      if (exactDifference.inHours < 24) {
        return isAr
            ? 'منذ ${exactDifference.inHours} س'
            : '${exactDifference.inHours} hr';
      }
      if (exactDifference.inDays < 7) {
        return isAr
            ? 'منذ ${exactDifference.inDays} ي'
            : '${exactDifference.inDays} d';
      }
      if (exactDifference.inDays < 30) {
        final weeks = (exactDifference.inDays / 7).floor();
        return isAr ? 'منذ $weeks أ' : '$weeks w';
      }
      return DateFormat('d MMM', locale).format(date);
    }

    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime storyDate = DateTime(date.year, date.month, date.day);
    final int diffInDays = today.difference(storyDate).inDays;
    final String time = DateFormat.jm(locale).format(date);

    if (exactDifference.inMinutes < 1 && !exactDifference.isNegative) {
      return AppL10n.current.justNow;
    }

    if (diffInDays == 0) {
      return AppL10n.current.todayAt(time);
    } else if (diffInDays == 1) {
      return AppL10n.current.yesterdayAt(time);
    } else {
      final bool isCurrentYear = date.year == now.year;
      final String dayMonth = DateFormat(
        isCurrentYear ? 'd MMMM' : 'd MMMM y',
        locale,
      ).format(date);

      if (isAr) {
        return '$time منذ $dayMonth';
      }
      return AppL10n.current.dateAtTime(dayMonth, time);
    }
  }

  static String getChatTime(DateTime date, {bool isChatList = false}) {
    final DateTime localDate = date.toLocal();
    final DateTime now = DateTime.now();
    final locale = AppLocale.normalize(
      SettingsRepository.instance.languageCode,
    );
    final String time = DateFormat.jm(locale).format(localDate);
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime msgDate = DateTime(
      localDate.year,
      localDate.month,
      localDate.day,
    );
    final int diffInDays = today.difference(msgDate).inDays;
    if (diffInDays == 0) {
      return isChatList ? time : AppL10n.current.today;
    }
    if (diffInDays == 1) {
      return AppL10n.current.yesterday;
    }
    if (diffInDays < 7) {
      return DateFormat.EEEE(locale).format(localDate);
    }
    if (isChatList) {
      return DateFormat('d MMMM', locale).format(localDate);
    } else {
      return DateFormat('d MMMM y', locale).format(localDate);
    }
  }

  static String getLastSeen(DateTime lastSeen) {
    final DateTime localDate = lastSeen.isUtc ? lastSeen.toLocal() : lastSeen;
    final locale = AppLocale.normalize(
      SettingsRepository.instance.languageCode,
    );
    final isAr = locale.startsWith('ar');

    final DateTime now = DateTime.now();
    final Duration diff = now.difference(localDate);
    final String time = DateFormat.jm(locale).format(localDate);
    final String dateFormatted = DateFormat('d/M/y', locale).format(localDate);

    if (diff.inSeconds < 30) return AppL10n.current.online;
    if (diff.inSeconds < 60) return AppL10n.current.justNow;
    if (diff.inMinutes < 60) {
      return isAr ? 'منذ ${diff.inMinutes} دقيقة' : '${diff.inMinutes}m ago';
    }

    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime seenDay = DateTime(
      localDate.year,
      localDate.month,
      localDate.day,
    );
    final int diffInDays = today.difference(seenDay).inDays;

    if (diffInDays == 0) {
      return isAr ? 'اليوم في $time' : AppL10n.current.todayAt(time);
    }
    if (diffInDays == 1) {
      return isAr ? 'أمس في $time' : AppL10n.current.yesterdayAt(time);
    }
    if (diffInDays < 7) {
      return isAr ? 'منذ $diffInDays أيام' : '$diffInDays days ago';
    }
    return isAr ? 'منذ $dateFormatted' : dateFormatted;
  }

  static String getMessageTime(DateTime date) {
    final locale = AppLocale.normalize(
      SettingsRepository.instance.languageCode,
    );
    return DateFormat.jm(locale).format(date.toLocal());
  }

  static String formatJoinedDate(DateTime? date, {String? locale}) {
    if (date == null) return '';
    final loc =
        locale ?? AppLocale.normalize(SettingsRepository.instance.languageCode);
    final localDate = date.isUtc ? date.toLocal() : date;
    return DateFormat.yMMMMd(loc).format(localDate);
  }

  static String getMembershipDuration(DateTime? date, {String? locale}) {
    if (date == null) return '';
    final loc =
        locale ?? AppLocale.normalize(SettingsRepository.instance.languageCode);
    final isAr = loc.startsWith('ar');
    final localDate = date.isUtc ? date.toLocal() : date;
    final now = DateTime.now();
    final difference = now.difference(localDate);

    if (difference.isNegative || difference.inDays < 1) {
      return isAr ? 'عضو جديد' : 'New member';
    }

    final days = difference.inDays;
    if (days < 7) {
      if (isAr) {
        if (days == 1) return 'منذ يوم';
        if (days == 2) return 'منذ يومين';
        if (days <= 10) return 'منذ $days أيام';
        return 'منذ $days يوماً';
      }
      return days == 1 ? '1 day ago' : '$days days ago';
    }

    final weeks = (days / 7).floor();
    if (days < 30) {
      if (isAr) {
        if (weeks == 1) return 'منذ أسبوع';
        if (weeks == 2) return 'منذ أسبوعين';
        return 'منذ $weeks أسابيع';
      }
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    }

    final months = (days / 30.4375).floor();
    if (days < 365) {
      if (isAr) {
        if (months <= 1) return 'منذ شهر';
        if (months == 2) return 'منذ شهرين';
        if (months <= 10) return 'منذ $months أشهر';
        return 'منذ $months شهراً';
      }
      return months <= 1 ? '1 month ago' : '$months months ago';
    }

    final years = (days / 365.25).floor();
    if (isAr) {
      if (years <= 1) return 'منذ سنة';
      if (years == 2) return 'منذ سنتين';
      if (years <= 10) return 'منذ $years سنوات';
      return 'منذ $years سنة';
    }
    return years <= 1 ? '1 year ago' : '$years years ago';
  }
}
