import 'package:flutter/material.dart';
import 'package:social_media_app/core/themes/app_colors.dart';

class AppThemes {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bgColor,
    primaryColor: AppColors.primaryColor,
    appBarTheme: AppBarTheme(backgroundColor: AppColors.bgColor, elevation: 0),
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryColor,
      surface: AppColors.bgColor,
    ),
  );
}
