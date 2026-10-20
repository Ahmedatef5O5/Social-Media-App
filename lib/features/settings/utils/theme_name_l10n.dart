import '../../../core/localization/l10n_extension.dart';
import '../../../core/themes/models/app_theme_model.dart';

extension ThemeNameL10n on AppLocalizations {
  /// Localized display name for a color theme.
  String themeName(AppThemeType type) => switch (type) {
    AppThemeType.ocean => themeNameOcean,
    AppThemeType.sunset => themeNameSunset,
    AppThemeType.forest => themeNameForest,
    AppThemeType.midnight => themeNameMidnight,
    AppThemeType.gold => themeNameGold,
    AppThemeType.glass => themeNameGlass,
    AppThemeType.lavender => themeNameLavender,
    AppThemeType.carbon => themeNameCarbon,
    AppThemeType.emerald => themeNameEmerald,
    AppThemeType.nordic => themeNameNordic,
    AppThemeType.grape => themeNameGrape,
    AppThemeType.sahara => themeNameSahara,
  };
}
