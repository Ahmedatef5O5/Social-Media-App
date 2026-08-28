import 'package:flutter/material.dart';

abstract final class AppTypography {
  static const String primaryFontFamily = 'Inter';
  static const String arabicFontFamily = 'IBM Plex Sans Arabic';
  static const String bundledEmojiFontFamily = 'NotoColorEmojiBundled';

  static const List<String> systemEmojiFontFallback = <String>[
    'Apple Color Emoji',
    'Segoe UI Emoji',
  ];

  static const List<String> emojiFontFallback = <String>[
    bundledEmojiFontFamily,
    ...systemEmojiFontFallback,
  ];

  static const TextStyle emojiTextStyle = TextStyle(
    inherit: false,
    fontFamily: null,
    fontFamilyFallback: emojiFontFallback,
    fontWeight: FontWeight.normal,
  );

  static const List<String> fontFallback = <String>[
    ...emojiFontFallback,
    primaryFontFamily,
    arabicFontFamily,
    'Noto Sans Arabic',
    'sans-serif',
  ];

  static const TextStyle displayLarge = TextStyle(
    fontFamilyFallback: fontFallback,
    fontSize: 32.0,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.5,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamilyFallback: fontFallback,
    fontSize: 28.0,
    fontWeight: FontWeight.w700,
    height: 1.29,
    letterSpacing: -0.25,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamilyFallback: fontFallback,
    fontSize: 24.0,
    fontWeight: FontWeight.w600,
    height: 1.33,
    letterSpacing: 0.0,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontFamilyFallback: fontFallback,
    fontSize: 22.0,
    fontWeight: FontWeight.w600,
    height: 1.36,
    letterSpacing: 0.0,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamilyFallback: fontFallback,
    fontSize: 20.0,
    fontWeight: FontWeight.w600,
    height: 1.40,
    letterSpacing: 0.0,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamilyFallback: fontFallback,
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
    height: 1.44,
    letterSpacing: 0.0,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamilyFallback: fontFallback,
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
    height: 1.33,
    letterSpacing: 0.0,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamilyFallback: fontFallback,
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
    height: 1.50,
    letterSpacing: 0.1,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamilyFallback: fontFallback,
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    height: 1.43,
    letterSpacing: 0.1,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamilyFallback: fontFallback,
    fontSize: 16.0,
    fontWeight: FontWeight.w400,
    height: 1.50,
    letterSpacing: 0.15,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamilyFallback: fontFallback,
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    height: 1.43,
    letterSpacing: 0.15,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamilyFallback: fontFallback,
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    height: 1.33,
    letterSpacing: 0.2,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamilyFallback: fontFallback,
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    height: 1.43,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamilyFallback: fontFallback,
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    height: 1.33,
    letterSpacing: 0.2,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamilyFallback: fontFallback,
    fontSize: 10.0,
    fontWeight: FontWeight.w500,
    height: 1.60,
    letterSpacing: 0.5,
  );

  // --- Complete Material 3 TextTheme Builder ---

  static TextTheme createTextTheme({
    required Color onSurface,
    required Color onSurfaceVariant,
    required Color primary,
  }) {
    return TextTheme(
      // Display
      displayLarge: displayLarge.copyWith(color: onSurface),
      displayMedium: displayMedium.copyWith(color: onSurface),
      displaySmall: displaySmall.copyWith(color: onSurface),

      // Headline
      headlineLarge: headlineLarge.copyWith(color: onSurface),
      headlineMedium: headlineMedium.copyWith(color: onSurface),
      headlineSmall: headlineSmall.copyWith(color: onSurface),

      // Title
      titleLarge: titleLarge.copyWith(color: onSurface),
      titleMedium: titleMedium.copyWith(color: onSurface),
      titleSmall: titleSmall.copyWith(color: onSurface),

      // Body
      bodyLarge: bodyLarge.copyWith(color: onSurface),
      bodyMedium: bodyMedium.copyWith(color: onSurfaceVariant),
      bodySmall: bodySmall.copyWith(color: onSurfaceVariant),

      // Label
      labelLarge: labelLarge.copyWith(color: onSurface),
      labelMedium: labelMedium.copyWith(color: onSurfaceVariant),
      labelSmall: labelSmall.copyWith(color: onSurfaceVariant),
    );
  }
}
