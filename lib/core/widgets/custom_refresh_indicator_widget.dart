import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';

import '../constants/app_images.dart';

class CustomRefreshIndicatorWidget extends StatelessWidget {
  final double? top;
  final double dy;
  final double? radius;
  final double opacity;
  final bool? animate;

  const CustomRefreshIndicatorWidget({
    super.key,
    required this.top,
    required this.dy,
    required this.radius,
    required this.opacity,
    this.animate,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top ?? dy.clamp(0, 15),
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: Material(
            elevation: 0.9,
            shadowColor: Theme.of(context).primaryColor.withValues(alpha: 0.6),
            shape: const CircleBorder(),
            child: CircleAvatar(
              radius: radius ?? 22,
              backgroundColor:
                  Theme.of(context).scaffoldBackgroundColor.withValues(),

              child: Center(
                child: Lottie.asset(
                  AppImages.trailLoadingLot,
                  width: 85,
                  height: 85,
                  fit: BoxFit.contain,
                  delegates: LottieDelegates(
                    values: [
                      ValueDelegate.colorFilter(
                        ['**'],
                        value: ColorFilter.mode(
                          Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.85),
                          BlendMode.srcATop,
                        ),
                      ),
                    ],
                  ),
                  animate: animate,
                  errorBuilder: (context, error, stackTrace) {
                    return const CustomLoadingIndicator();
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
