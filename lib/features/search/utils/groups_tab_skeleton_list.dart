import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/widgets/skeleton_shapes.dart';
import 'search_view_metrics.dart';

class GroupsTabSkeletonList extends StatelessWidget {
  const GroupsTabSkeletonList({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlightColor = isDark ? Colors.grey.shade700 : Colors.grey.shade100;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          SearchViewMetrics.horizontalPadding,
          SearchViewMetrics.topGap,
          SearchViewMetrics.horizontalPadding,
          SearchViewMetrics.bottomGap,
        ),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 8,
        separatorBuilder: (_, __) => const Gap(SearchViewMetrics.itemGap),
        itemBuilder: (context, _) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const SkeletonCircle(size: 48),
            title: const Align(
              alignment: Alignment.centerLeft,
              child: SkeletonBox(height: 14, width: 140, radius: 4),
            ),
            subtitle: const Align(
              alignment: Alignment.centerLeft,
              child: SkeletonBox(height: 12, width: 80, radius: 4),
            ),
          );
        },
      ),
    );
  }
}
