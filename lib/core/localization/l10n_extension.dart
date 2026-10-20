import 'package:flutter/widgets.dart';
import 'package:social_media_app/l10n/generated/app_localizations.dart';
export 'package:social_media_app/l10n/generated/app_localizations.dart';

extension LocalizationContext on BuildContext {
  /// Shorthand for `AppLocalizations.of(context)!`.
  AppLocalizations get l10n => AppLocalizations.of(this)!;

  /// True when the active UI locale is Arabic.
  bool get isArabicLocale => Localizations.localeOf(this).languageCode == 'ar';

  /// Arabic letters connect to each other; any non-zero tracking breaks the
  /// joining in Flutter's text shaping. Use for every `TextStyle.letterSpacing`
  /// that can render localized UI text: `letterSpacing: context.ls(-0.2)`.
  double ls(double value) => isArabicLocale ? 0 : value;
}
