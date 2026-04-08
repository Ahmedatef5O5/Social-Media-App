import 'package:flutter/material.dart';
import 'package:social_media_app/core/widgets/custom_refresh_indicator_widget.dart';

class ProfileRefreshIndicator extends StatelessWidget {
  final ValueNotifier<double> _refreshProgress;
  final ValueNotifier<bool> _isRefreshing;

  const ProfileRefreshIndicator({
    super.key,
    required ValueNotifier<double> refreshProgress,
    required ValueNotifier<bool> isRefreshing,
  }) : _refreshProgress = refreshProgress,
       _isRefreshing = isRefreshing;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: _refreshProgress,
      builder: (context, value, _) {
        if (value <= 0) return const SizedBox.shrink();

        final clampedValue = value.clamp(0.0, 1.0);
        final curveValue = Curves.easeInOut.transform(clampedValue);
        final dy = curveValue * 80;

        return CustomRefreshIndicatorWidget(
          top: MediaQuery.of(context).padding.top + 16,

          dy: dy,
          radius: 22,
          opacity: clampedValue,
          animate: _isRefreshing.value || _refreshProgress.value > 0,
        );
      },
    );
  }
}
