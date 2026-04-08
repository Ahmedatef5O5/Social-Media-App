import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/core/widgets/custom_refresh_indicator_widget.dart';

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
            final double clampedValue = controller.value.clamp(0.0, 1.0);
            final double curveValue = Curves.easeInOut.transform(clampedValue);
            final double dy = curveValue * 80.0;

            return Stack(
              clipBehavior: Clip.none,
              alignment: alignment ?? Alignment.topCenter,
              children: <Widget>[
                Positioned.fill(child: child),

                if (!controller.isIdle)
                  CustomRefreshIndicatorWidget(
                    top: top,
                    dy: dy,
                    radius: radius,
                    opacity: controller.value.clamp(0.0, 1.0),
                    animate:
                        controller.isRefreshEnabled || controller.isDragging,
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
