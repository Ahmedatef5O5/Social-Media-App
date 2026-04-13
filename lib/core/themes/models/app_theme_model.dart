import 'package:flutter/material.dart';
import 'package:social_media_app/core/themes/app_colors.dart';

enum AppThemeType {
  ocean,
  sunset,
  forest,
  midnight,
  gold,
  glass,
  lavender,
  carbon,
  emerald,
  nordic,
  grape,
  sahara,
}

class AppThemeModel {
  final AppThemeType type;
  final String name;
  final String emoji;
  final Color bgBase;
  final Color bgCircle;
  final Color primaryColor;

  AppThemeModel({
    required this.type,
    required this.name,
    required this.emoji,
    required this.bgBase,
    required this.bgCircle,
    required this.primaryColor,
  });

  static List<AppThemeModel> themes = [
    AppThemeModel(
      type: AppThemeType.ocean,
      name: 'Ocean',
      emoji: '🌊',
      bgBase: Colors.white,
      bgCircle: Color(0xffD8F1FE),
      primaryColor: Color(0xff007AFF),
    ),

    AppThemeModel(
      type: AppThemeType.sunset,
      name: 'Sunset',
      emoji: '🌅',
      bgBase: Color(0xFFFFF8F0),
      bgCircle: Color(0xFFFFD6B0),
      primaryColor: Color(0xFFE8650A),
    ),
    AppThemeModel(
      type: AppThemeType.forest,
      name: 'Forest',
      emoji: '🌿',
      bgBase: Color(0xFFF2FAF4),
      bgCircle: Color(0xFFC2E8CC),
      primaryColor: Color(0xFF2E7D52),
    ),
    AppThemeModel(
      type: AppThemeType.midnight,
      name: 'Midnight',
      emoji: '🌙',
      bgBase: Color(0xFF12141C),
      bgCircle: Color(0xFF2A2D45),
      primaryColor: Color(0xFF7B8FFF),
    ),
    AppThemeModel(
      type: AppThemeType.gold,
      name: 'Royal Gold',
      emoji: '✨',
      bgBase: Color(0xFFF9F6F0),
      bgCircle: Color(0xFFF3E5AB),
      primaryColor: Color(0xFFC5A059),
    ),
    AppThemeModel(
      type: AppThemeType.glass,
      name: 'Ice Glass',
      emoji: '💎',
      bgBase: Color(0xFFF0F2F5),
      bgCircle: Color(0xFFE1E8F0),
      primaryColor: Color(0xFF607D8B),
    ),
    AppThemeModel(
      type: AppThemeType.lavender,
      name: 'Lavender',
      emoji: '🔮',
      // emoji: '💜',
      bgBase: Color(0xFFF8F7FF),
      bgCircle: Color(0xFFEBE9FF),
      primaryColor: Color(0xFF7E60FF),
    ),
    AppThemeModel(
      type: AppThemeType.carbon,
      name: 'Carbon',
      emoji: '🌚',
      bgBase: Color(0xFF0D0D0D),
      // bgCircle: Colors.transparent,
      // bgCircle: Color.fromARGB(69, 26, 26, 26),
      bgCircle: Color(0xFF1E2224),
      primaryColor: Color(0xFF00E5FF),
    ),
    AppThemeModel(
      type: AppThemeType.emerald,
      name: 'Emerald',
      emoji: '🌲',
      bgBase: Color(0xFF0A120E),
      bgCircle: Color(0xFF14261D),
      primaryColor: Color(0xFF2ECC71),
    ),
    AppThemeModel(
      type: AppThemeType.nordic,
      name: 'Nordic',
      emoji: '🏔️',
      bgBase: Color(0xFFF4F7F9),
      bgCircle: Color(0xFFE0E5EC),
      primaryColor: Color(0xFFD48181),
    ),
    AppThemeModel(
      type: AppThemeType.grape,
      name: 'Cyber Grape',
      emoji: '🍇',
      bgBase: Color(0xFF100B1A),
      bgCircle: Color(0xFF1F162E),
      primaryColor: Color(0xFFBB86FC),
    ),
    AppThemeModel(
      type: AppThemeType.sahara,
      name: 'Sahara',
      emoji: '🏜️',
      bgBase: Color(0xFFFDF8F2),
      bgCircle: Color(0xFFF4EADF),
      primaryColor: Color(0xFFBC8E5B),
    ),
  ];

  static AppThemeModel fromString(String? typeName) => themes.firstWhere(
    (t) => t.type.name == typeName,
    orElse: () => themes.first,
  );

  static AppThemeModel fromType(AppThemeType type) =>
      themes.firstWhere((t) => t.type == type);

  ThemeData get themeData {
    final bool isDark = bgBase.computeLuminance() < 0.5;
    final Color textColor = isDark ? AppColors.white : AppColors.black87;
    final Color secondaryTextColor =
        isDark ? AppColors.white70 : AppColors.black54;
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: bgBase,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        surface: bgBase,
        brightness: isDark ? Brightness.dark : Brightness.light,
        onSurface: textColor,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bgBase,
        indicatorColor: primaryColor.withValues(alpha: 0.2),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: bgBase,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryColor),
        titleTextStyle: TextStyle(
          color: primaryColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      tabBarTheme: TabBarTheme(
        labelColor: primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(60),
        ),
      ),

      textTheme: TextTheme(
        displayLarge: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: textColor),
        bodyMedium: TextStyle(color: secondaryTextColor),
        labelLarge: TextStyle(color: primaryColor),
      ),
    );
  }

  String toStorageString() => type.name;

  bool get isDark => bgBase.computeLuminance() < 0.5;

  bool get shouldShowCircles => !isDark;
}
