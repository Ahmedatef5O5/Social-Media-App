import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shimmer/shimmer.dart';
import 'package:gap/gap.dart';
import '../../../core/widgets/skeleton_shapes.dart';
import '../utils/discover_grid_metrics.dart';

class DiscoverPeopleSkeleton extends StatelessWidget {
  const DiscoverPeopleSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlightColor = isDark ? Colors.grey.shade700 : Colors.grey.shade100;

    final cardColor = theme.colorScheme.surface;
    final borderColor = theme.colorScheme.outlineVariant.withValues(
      alpha: 0.12,
    );

    final screenWidth = MediaQuery.sizeOf(context).width;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            period: const Duration(milliseconds: 1200),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(height: 22, width: screenWidth * 0.4),
                    const Gap(8),
                    SkeletonBox(height: 12, width: screenWidth * 0.3),
                  ],
                ),
                const SkeletonCircle(size: 40),
              ],
            ),
          ),
        ),

        // [FIX] استخدام MasonryGridView.count (RenderBox) بدلاً من SliverMasonryGrid داخل Expanded/Column
        Expanded(
          child: MasonryGridView.count(
            crossAxisCount: DiscoverGridMetrics.crossAxisCount,
            mainAxisSpacing: DiscoverGridMetrics.mainAxisSpacing,
            crossAxisSpacing: DiscoverGridMetrics.crossAxisSpacing,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            itemBuilder: (_, index) {
              final height = index.isEven ? 260.0 : 220.0;
              return SizedBox(
                height: height,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Shimmer.fromColors(
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                    period: const Duration(milliseconds: 1200),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SkeletonCircle(size: 64),
                        const Gap(10),
                        SkeletonBox(height: 13, width: 90),
                        const Gap(6),
                        SkeletonBox(height: 10, width: 60),
                        const Spacer(),
                        SkeletonBox(
                          height: 36,
                          width: double.infinity,
                          radius: 10,
                        ),
                        const Gap(6),
                        SkeletonBox(
                          height: 36,
                          width: double.infinity,
                          radius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
