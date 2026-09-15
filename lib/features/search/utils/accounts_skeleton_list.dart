import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:gap/gap.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/widgets/skeleton_shapes.dart';
import '../../discover/utils/discover_grid_metrics.dart';
import 'search_view_metrics.dart';

class AccountsSkeletonList extends StatelessWidget {
  final bool _isSliver;
  const AccountsSkeletonList({super.key}) : _isSliver = false;
  const AccountsSkeletonList.sliver({super.key}) : _isSliver = true;

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

    const padding = EdgeInsets.fromLTRB(
      SearchViewMetrics.horizontalPadding,
      SearchViewMetrics.topGap,
      SearchViewMetrics.horizontalPadding,
      SearchViewMetrics.bottomGap,
    );

    if (_isSliver) {
      return SliverPadding(
        padding: padding,
        sliver: SliverMasonryGrid.count(
          crossAxisCount: DiscoverGridMetrics.crossAxisCount,
          mainAxisSpacing: DiscoverGridMetrics.mainAxisSpacing,
          crossAxisSpacing: DiscoverGridMetrics.crossAxisSpacing,
          childCount: 6,
          itemBuilder:
              (_, index) => _buildSkeletonItem(
                index,
                cardColor,
                borderColor,
                baseColor,
                highlightColor,
              ),
        ),
      );
    }

    return MasonryGridView.count(
      crossAxisCount: DiscoverGridMetrics.crossAxisCount,
      mainAxisSpacing: DiscoverGridMetrics.mainAxisSpacing,
      crossAxisSpacing: DiscoverGridMetrics.crossAxisSpacing,
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      itemBuilder:
          (_, index) => _buildSkeletonItem(
            index,
            cardColor,
            borderColor,
            baseColor,
            highlightColor,
          ),
    );
  }

  Widget _buildSkeletonItem(
    int index,
    Color cardColor,
    Color borderColor,
    Color baseColor,
    Color highlightColor,
  ) {
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
              SkeletonBox(height: 36, width: double.infinity, radius: 10),
              const Gap(6),
              SkeletonBox(height: 36, width: double.infinity, radius: 10),
            ],
          ),
        ),
      ),
    );
  }
}
