import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:gap/gap.dart';

class CommentsShimmerSkeleton extends StatelessWidget {
  const CommentsShimmerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;
    const skeletonColor = Colors.white;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: 4,
        separatorBuilder: (context, index) => const Gap(24),
        itemBuilder: (context, index) {
          final hasMedia = index % 2 == 1;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(radius: 20, backgroundColor: skeletonColor),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 100,
                          height: 12,
                          decoration: BoxDecoration(
                            color: skeletonColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const Gap(8),
                        Container(
                          width: 40,
                          height: 10,
                          decoration: BoxDecoration(
                            color: skeletonColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                    const Gap(8),
                    Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        color: skeletonColor,
                        borderRadius: BorderRadius.circular(
                          16,
                        ).copyWith(topLeft: const Radius.circular(4)),
                      ),
                    ),
                    if (hasMedia) ...[
                      const Gap(8),
                      Container(
                        width: 180,
                        height: 140,
                        decoration: BoxDecoration(
                          color: skeletonColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ],
                    const Gap(8),
                    Row(
                      children: [
                        Container(
                          width: 30,
                          height: 10,
                          decoration: BoxDecoration(
                            color: skeletonColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const Gap(16),
                        Container(
                          width: 40,
                          height: 10,
                          decoration: BoxDecoration(
                            color: skeletonColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
