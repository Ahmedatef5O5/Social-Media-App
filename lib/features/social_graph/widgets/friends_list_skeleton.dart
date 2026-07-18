import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:gap/gap.dart';
import '../../../core/widgets/skeleton_shapes.dart';

class FriendsListSkeleton extends StatelessWidget {
  final bool isMe;
  const FriendsListSkeleton({super.key, required this.isMe});

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

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: 10,
      separatorBuilder: (_, __) => const Gap(10),
      itemBuilder: (_, __) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            period: const Duration(milliseconds: 1200),
            child: Row(
              children: [
                const SkeletonCircle(size: 48),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(height: 14, width: screenWidth * 0.32),
                      const Gap(8),
                      SkeletonBox(height: 10, width: screenWidth * 0.22),
                    ],
                  ),
                ),
                if (isMe) ...[const Gap(8), const SkeletonCircle(size: 34)],
              ],
            ),
          ),
        );
      },
    );
  }
}
