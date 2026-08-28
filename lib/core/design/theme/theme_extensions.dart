import 'package:flutter/material.dart';
import 'package:social_media_app/core/design/tokens/colors.dart';
import 'package:social_media_app/core/design/tokens/dimensions.dart';

class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final AppPalette palette;
  final Color surfaceElevated;
  final Color success;
  final Color warning;
  final double glassBlurSigma;
  final double glassSurfaceOpacity;
  final double glassBorderOpacity;

  const AppThemeExtension({
    required this.palette,
    required this.surfaceElevated,
    required this.success,
    required this.warning,
    required this.glassBlurSigma,
    required this.glassSurfaceOpacity,
    required this.glassBorderOpacity,
  });

  factory AppThemeExtension.fromPalette(AppPalette palette) {
    final isDark = palette.isDark;
    return AppThemeExtension(
      palette: palette,
      surfaceElevated: palette.surfaceElevated,
      success: palette.success,
      warning: palette.warning,
      glassBlurSigma: AppDimensions.glassBlurSigma,
      glassSurfaceOpacity:
          isDark
              ? AppDimensions.glassSurfaceOpacityDark
              : AppDimensions.glassSurfaceOpacityLight,
      glassBorderOpacity:
          isDark
              ? AppDimensions.glassBorderOpacityDark
              : AppDimensions.glassBorderOpacityLight,
    );
  }

  @override
  ThemeExtension<AppThemeExtension> copyWith({
    AppPalette? palette,
    Color? surfaceElevated,
    Color? success,
    Color? warning,
    double? glassBlurSigma,
    double? glassSurfaceOpacity,
    double? glassBorderOpacity,
  }) {
    return AppThemeExtension(
      palette: palette ?? this.palette,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      glassBlurSigma: glassBlurSigma ?? this.glassBlurSigma,
      glassSurfaceOpacity: glassSurfaceOpacity ?? this.glassSurfaceOpacity,
      glassBorderOpacity: glassBorderOpacity ?? this.glassBorderOpacity,
    );
  }

  @override
  ThemeExtension<AppThemeExtension> lerp(
    covariant ThemeExtension<AppThemeExtension>? other,
    double t,
  ) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      palette: t < 0.5 ? palette : other.palette,
      surfaceElevated:
          Color.lerp(surfaceElevated, other.surfaceElevated, t) ??
          surfaceElevated,
      success: Color.lerp(success, other.success, t) ?? success,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      glassBlurSigma:
          (glassBlurSigma + (other.glassBlurSigma - glassBlurSigma) * t),
      glassSurfaceOpacity:
          (glassSurfaceOpacity +
              (other.glassSurfaceOpacity - glassSurfaceOpacity) * t),
      glassBorderOpacity:
          (glassBorderOpacity +
              (other.glassBorderOpacity - glassBorderOpacity) * t),
    );
  }
}

extension AppThemeContextExtension on BuildContext {
  AppThemeExtension get appTheme =>
      Theme.of(this).extension<AppThemeExtension>() ??
      AppThemeExtension.fromPalette(AppColors.oceanLight);

  AppPalette get palette => appTheme.palette;

  TextTheme get typography => Theme.of(this).textTheme;
}
