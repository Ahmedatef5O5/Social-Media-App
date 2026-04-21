import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:gap/gap.dart';

class DiscoverPeopleSkeleton extends StatelessWidget {
  const DiscoverPeopleSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlightColor = isDark ? Colors.grey.shade700 : Colors.grey.shade100;

    final cardColor = theme.colorScheme.surface;
    final borderColor = theme.colorScheme.outlineVariant.withValues(alpha: 0.5);

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
                _SkeletonBox(height: 26, width: screenWidth * 0.43),
                const _SkeletonCircle(size: 26),
              ],
            ),
          ),
        ),

        Expanded(
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 8,
            separatorBuilder: (_, __) => const Gap(16),
            itemBuilder: (_, __) {
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color:
                          isDark
                              ? Colors.black54
                              : Colors.grey.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Shimmer.fromColors(
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                  period: const Duration(milliseconds: 1200),
                  child: Row(
                    children: [
                      // Avatar
                      const _SkeletonCircle(size: 48),
                      const Gap(12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SkeletonBox(height: 14, width: screenWidth * 0.35),
                            const Gap(10),
                            _SkeletonBox(height: 10, width: screenWidth * 0.2),
                          ],
                        ),
                      ),

                      const Gap(12),

                      // Follow button
                      const _SkeletonBox(height: 34, width: 95, radius: 18),
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

class _SkeletonBox extends StatelessWidget {
  final double height;
  final double width;
  final double radius;

  const _SkeletonBox({
    required this.height,
    required this.width,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _SkeletonCircle extends StatelessWidget {
  final double size;

  const _SkeletonCircle({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}
