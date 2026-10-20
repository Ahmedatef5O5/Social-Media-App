import 'package:flutter/widgets.dart';

import '../../features/settings/repository/settings_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import 'app_locale.dart';

/// Context-free access to the CURRENT app language.
///
/// Use ONLY where no `BuildContext` exists (cubits, services, controllers,
/// static helpers, toasts raised from callbacks). Widgets must keep using
/// `context.l10n`, which also rebuilds when the language changes.
abstract final class AppL10n {
  static AppLocalizations get current => lookupAppLocalizations(
    Locale(AppLocale.normalize(SettingsRepository.instance.languageCode)),
  );
}
