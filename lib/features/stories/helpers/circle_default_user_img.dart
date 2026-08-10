import 'package:flutter/material.dart';
import '../../../core/constants/app_images.dart';

class CircleDefaultUserImage extends StatelessWidget {
  const CircleDefaultUserImage({
    super.key,
    required this.theme,
    required this.cardWidth,
  });

  final ThemeData theme;
  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.scaffoldBackgroundColor,
      alignment: Alignment.bottomCenter,
      child: Container(
        width: cardWidth,
        height: cardWidth,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: AssetImage(AppImages.defaultUserImg),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
