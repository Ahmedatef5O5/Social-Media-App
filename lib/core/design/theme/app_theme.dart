import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_media_app/core/design/tokens/colors.dart';
import 'package:social_media_app/core/design/tokens/dimensions.dart';
import 'package:social_media_app/core/design/tokens/radii.dart';
import 'package:social_media_app/core/design/tokens/spacing.dart';
import 'package:social_media_app/core/design/tokens/typography.dart';
import 'theme_extensions.dart';

/// Master ThemeData builder for the Social Mate Design System.

abstract final class AppTheme {
  static ThemeData buildTheme(AppPalette palette) {
    final isDark = palette.isDark;
    final colorScheme = palette.toColorScheme();

    final textTheme = AppTypography.createTextTheme(
      onSurface: palette.onSurface,
      onSurfaceVariant: palette.onSurfaceVariant,
      primary: palette.primary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: palette.brightness,
      primaryColor: palette.primary,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.background,
      canvasColor: palette.background,
      cardColor: palette.surface,
      dividerColor: palette.outlineVariant,
      unselectedWidgetColor: palette.onSurfaceVariant,

      // --- Icon Themes ---
      iconTheme: IconThemeData(
        color: palette.onSurface,
        size: AppDimensions.iconMedium,
      ),
      primaryIconTheme: IconThemeData(
        color: palette.onSurface,
        size: AppDimensions.iconMedium,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: palette.onSurface),
      ),

      // --- Typography ---
      fontFamily: null,
      fontFamilyFallback: AppTypography.fontFallback,
      textTheme: textTheme,
      primaryTextTheme: textTheme,

      // --- AppBar Theme ---
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: palette.background,
        foregroundColor: palette.onSurface,
        centerTitle: false,
        titleSpacing: AppSpacing.space4,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(
          color: palette.onSurface,
          size: AppDimensions.iconLarge,
        ),
        actionsIconTheme: IconThemeData(
          color: palette.onSurface,
          size: AppDimensions.iconLarge,
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: palette.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),

      // --- Card Theme (Flat Level 0) ---
      cardTheme: CardThemeData(
        elevation: 0,
        color: palette.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.radiusLg,
          side: BorderSide(
            color: palette.outline,
            width: AppDimensions.borderWidthDefault,
          ),
        ),
      ),

      // --- Text Field / Input Theme ---
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surfaceVariant,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space6,
          vertical: AppSpacing.space5,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: palette.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: palette.onSurfaceVariant,
        ),
        floatingLabelStyle: textTheme.titleSmall?.copyWith(
          color: palette.primary,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadii.radiusMd,
          borderSide: BorderSide(
            color: palette.outline,
            width: AppDimensions.borderWidthDefault,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.radiusMd,
          borderSide: BorderSide(
            color: palette.outline,
            width: AppDimensions.borderWidthDefault,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.radiusMd,
          borderSide: BorderSide(
            color: palette.primary,
            width: AppDimensions.borderWidthFocused,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadii.radiusMd,
          borderSide: BorderSide(
            color: palette.error,
            width: AppDimensions.borderWidthDefault,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadii.radiusMd,
          borderSide: BorderSide(
            color: palette.error,
            width: AppDimensions.borderWidthFocused,
          ),
        ),
      ),

      // --- Elevated Button Theme (Primary CTA) ---
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: palette.primary,
          foregroundColor: palette.onPrimary,
          disabledBackgroundColor: palette.outline,
          disabledForegroundColor: palette.onSurfaceVariant,
          minimumSize: const Size(
            AppDimensions.buttonMinWidth,
            AppDimensions.buttonHeight,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.radiusMd),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space6),
        ),
      ),

      // --- Outlined Button Theme (Secondary CTA) ---
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: palette.primary,
          side: BorderSide(
            color: palette.primary,
            width: AppDimensions.borderWidthDefault,
          ),
          minimumSize: const Size(
            AppDimensions.buttonMinWidth,
            AppDimensions.buttonHeight,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.radiusMd),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space6),
        ),
      ),

      // --- Text Button Theme ---
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.primary,
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.radiusMd),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
            vertical: AppSpacing.space2,
          ),
        ),
      ),

      // --- Tab Bar Theme (Underline indicator) ---
      tabBarTheme: TabBarThemeData(
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: palette.outlineVariant,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: palette.primary, width: 2.5),
        ),
        labelColor: palette.onSurface,
        unselectedLabelColor: palette.onSurfaceVariant,
        labelStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w400,
        ),
      ),

      // --- Bottom Sheet Theme ---
      bottomSheetTheme: BottomSheetThemeData(
        elevation: 0,
        backgroundColor: isDark ? palette.surfaceElevated : palette.surface,
        modalBackgroundColor:
            isDark ? palette.surfaceElevated : palette.surface,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.bottomSheet),
        dragHandleColor: palette.onSurfaceVariant.withValues(alpha: 0.3),
        dragHandleSize: const Size(
          AppDimensions.bottomSheetHandleWidth,
          AppDimensions.bottomSheetHandleHeight,
        ),
      ),

      // --- Dialog Theme ---
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: isDark ? palette.surfaceElevated : palette.surface,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.radiusXl),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: palette.onSurface,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: palette.onSurfaceVariant,
        ),
      ),

      // --- Divider Theme ---
      dividerTheme: DividerThemeData(
        color: palette.outlineVariant,
        thickness: AppDimensions.dividerThickness,
        space: 1.0,
      ),

      // --- Extensions Registration ---
      extensions: [AppThemeExtension.fromPalette(palette)],
    );
  }

  /// Convenience builder from theme key string (e.g., 'ocean', 'sunset')
  static ThemeData buildThemeFromName(
    String themeName, {
    required bool isDark,
  }) {
    final palette = AppColors.getPalette(themeName, isDark: isDark);
    return buildTheme(palette);
  }
}
