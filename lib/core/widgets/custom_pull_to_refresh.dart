import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import '../constants/app_images.dart';

class CustomPullToRefresh extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final double? radius;
  final double? top;
  final AlignmentGeometry? alignment;
  final bool transform;

  const CustomPullToRefresh({
    super.key,
    required this.child,
    required this.onRefresh,
    this.radius,
    this.top,
    this.transform = true,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return CustomRefreshIndicator(
      onRefresh: onRefresh,
      builder: (
        BuildContext context,
        Widget child,
        IndicatorController controller,
      ) {
        return AnimatedBuilder(
          animation: controller,
          builder: (BuildContext context, _) {
            //
            final double clampedValue = controller.value.clamp(0.0, 1.0);
            final double curveValue = Curves.easeInOut.transform(clampedValue);
            final double dy = curveValue * 80.0;
            // final double dy = (controller.value * 120) - 60;

            return Stack(
              clipBehavior: Clip.none,
              alignment: alignment ?? Alignment.topCenter,
              children: <Widget>[
                Positioned.fill(child: child),

                if (!controller.isIdle)
                  Positioned(
                    top: dy.clamp(0, 60),
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: controller.value.clamp(0.0, 1.0),
                        child: Material(
                          elevation: 0.9,
                          shadowColor: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.6),
                          shape: const CircleBorder(),
                          child: CircleAvatar(
                            radius: radius ?? 24,
                            backgroundColor:
                                Theme.of(
                                  context,
                                ).scaffoldBackgroundColor.withValues(),

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
                                animate:
                                    controller.isRefreshEnabled ||
                                    controller.isDragging,
                                errorBuilder: (context, error, stackTrace) {
                                  return const CustomLoadingIndicator();
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // child,
              ],
            );
          },
        );
      },
      child: child,
    );
  }
}
