import 'package:flutter/material.dart';
import 'package:social_media_app/core/themes/app_colors.dart';

class AppGradients {
  static const LinearGradient doubleCircleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.bgColor, AppColors.white, AppColors.bgColor],
    stops: [0.1, 0.5, 0.9],
  );
}
