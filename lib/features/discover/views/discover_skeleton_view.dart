import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:gap/gap.dart';
import '../../../core/widgets/skeleton_shapes.dart';

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

        Expanded(
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: 6,
            separatorBuilder: (_, __) => const Gap(14),
            itemBuilder: (_, __) {
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                ),
                child: Shimmer.fromColors(
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                  period: const Duration(milliseconds: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const SkeletonCircle(size: 52),
                          const Gap(12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SkeletonBox(
                                  height: 15,
                                  width: screenWidth * 0.34,
                                ),
                                const Gap(8),
                                SkeletonBox(
                                  height: 11,
                                  width: screenWidth * 0.2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Gap(14),
                      Row(
                        children: [
                          Expanded(
                            child: SkeletonBox(
                              height: 38,
                              width: double.infinity,
                              radius: 19,
                            ),
                          ),
                          const Gap(10),
                          Expanded(
                            child: SkeletonBox(
                              height: 38,
                              width: double.infinity,
                              radius: 19,
                            ),
                          ),
                        ],
                      ),
                    ],
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
