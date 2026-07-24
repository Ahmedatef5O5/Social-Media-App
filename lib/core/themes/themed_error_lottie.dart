import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:social_media_app/core/themes/models/app_theme_model.dart';

class ThemedErrorLottie extends StatelessWidget {
  final AppThemeModel theme;
  final String assetPath;
  final double? height;
  final double? width;
  final BoxFit fit;
  final bool repeat;

  const ThemedErrorLottie({
    super.key,
    required this.theme,
    required this.assetPath,
    this.height,
    this.width,
    this.fit = BoxFit.contain,
    this.repeat = true,
  });

  static const List<String> _primaryLayers = [
    'Layer 19',
    'Layer 20',
    'Layer 21',
    'Layer 25',
    'Layer 30',
    'Layer 32',
    'Layer 36',
    'Group 6', // Eye Rectangle
  ];

  static const List<List<String>> _specificPrimaryPaths = [
    ['Layer 45', 'Group 1', '**'], // Vase
    ['Layer 46', 'Group 1', '**'], // Flower 1 petal
    ['Layer 46', 'Group 3', '**'], // Flower 1 petal
    ['Layer 47', 'Group 1', '**'], // Flower 2 petal
    ['Layer 47', 'Group 3', '**'], // Flower 2 petal
    ['Layer 48', 'Group 1', '**'], // Flower 3 petal
  ];

  static const List<String> _shadeLayers = [
    'torso',
    'Neck',
    'Layer 37',
    'Layer 38',
  ];

  static const List<String> _detailLayers = [
    'Layer 11',
    'Layer 16',
    'Layer 17',
    'Layer 22',
    'Layer 44',
    'Group 2',
    'Group 3',
    'Group 4',
  ];

  static const List<String> _backgroundLayers = [
    'Layer 43',
    'Layer 49',
    'Layer 50',
    'Layer 51',
    'Layer 53',
    'Layer 55',
    'Layer 56',
    'Layer 57',
    'Layer 58',
    'Layer 59',
    'Layer 52',
    'Layer 65',
    'Layer 66',
    'Layer 67',
  ];

  List<ValueDelegate> _buildDelegates() {
    ColorFilter filterFor(Color c) => ColorFilter.mode(c, BlendMode.srcATop);

    return [
      for (final layer in _primaryLayers)
        ValueDelegate.colorFilter([
          layer,
          '**',
        ], value: filterFor(theme.primaryColor)),

      for (final path in _specificPrimaryPaths)
        ValueDelegate.colorFilter(path, value: filterFor(theme.primaryColor)),

      ValueDelegate.colorFilter(
        ['Group 1', '**'],
        value: ColorFilter.mode(
          theme.primaryColor.withValues(alpha: 0.85),
          BlendMode.srcATop,
        ),
      ),

      for (final layer in _shadeLayers)
        ValueDelegate.colorFilter([
          layer,
          '**',
        ], value: filterFor(theme.lottieShadeColor)),

      for (final layer in _detailLayers)
        ValueDelegate.colorFilter([
          layer,
          '**',
        ], value: filterFor(theme.lottieDetailColor)),

      for (final layer in _backgroundLayers)
        ValueDelegate.colorFilter([
          layer,
          '**',
        ], value: filterFor(theme.bgCircle)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      assetPath,
      height: height,
      width: width,
      fit: fit,
      repeat: repeat,
      delegates: LottieDelegates(values: _buildDelegates()),
    );
  }
}
