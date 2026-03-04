import 'package:flutter/material.dart';
import 'app_colors.dart';

class BackgroundThemeWidget extends StatelessWidget {
  final Widget child;
  const BackgroundThemeWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(color: Colors.white),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.bgColor,
                    AppColors.bgColor.withValues(alpha: 0.01),
                  ],
                  stops: const [0.2, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.bgColor,
                    AppColors.bgColor.withValues(alpha: 0.01),
                  ],
                  stops: const [0.2, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(child: child),
        ],
      ),
    );
  }
}
