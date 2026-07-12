import 'package:flutter/material.dart';
import '../themes/app_colors.dart';

enum AppToastType { success, error, warning, info, save }

extension AppToastTypeStyle on AppToastType {
  Color get color {
    switch (this) {
      case AppToastType.success:
        return const Color(0xFF2E7D32);
      case AppToastType.error:
        return const Color(0xFFD32F2F);
      case AppToastType.warning:
        return const Color(0xFFED6C02);
      case AppToastType.info:
        return const Color(0xFF007AFF);
      case AppToastType.save:
        return AppColors.goldenYellow;
    }
  }

  IconData get icon {
    switch (this) {
      case AppToastType.success:
        return Icons.check_circle_rounded;
      case AppToastType.error:
        return Icons.error_rounded;
      case AppToastType.warning:
        return Icons.warning_rounded;
      case AppToastType.info:
        return Icons.info_rounded;
      case AppToastType.save:
        return Icons.bookmark_rounded;
    }
  }
}
