import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'search_view_metrics.dart';

class ReelsGridSkeleton extends StatelessWidget {
  const ReelsGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlightColor = isDark ? Colors.grey.shade700 : Colors.grey.shade100;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        SearchViewMetrics.horizontalPadding,
        SearchViewMetrics.topGap,
        SearchViewMetrics.horizontalPadding,
        SearchViewMetrics.bottomGap,
      ),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 9 / 16,
      ),
      itemCount: 12,
      itemBuilder: (_, __) {
        return Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          period: const Duration(milliseconds: 1200),
          child: Container(color: Colors.white),
        );
      },
    );
  }
}
