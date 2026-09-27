import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'story_card_widget.dart';

class StoriesListSkeleton extends StatelessWidget {
  final int itemCount;

  const StoriesListSkeleton({super.key, this.itemCount = 5});

  static const List<double> _labelWidthFactors = [0.65, 0.75, 0.70, 0.80, 0.62];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        primary: false,
        padding: const EdgeInsets.only(left: 4, right: 12),
        clipBehavior: Clip.none,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          final labelWidth =
              StoryCardWidget.cardWidth *
              _labelWidthFactors[index % _labelWidthFactors.length];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _StoryCardSkeletonItem(labelWidth: labelWidth),
          );
        },
      ),
    );
  }
}

class _StoryCardSkeletonItem extends StatelessWidget {
  final double labelWidth;

  const _StoryCardSkeletonItem({required this.labelWidth});

  static const Color _skeletonColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: StoryCardWidget.cardWidth,
      height: StoryCardWidget.cardHeight,
      decoration: BoxDecoration(
        color: _skeletonColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _skeletonColor,
                shape: BoxShape.circle,
                border: Border.all(color: _skeletonColor),
              ),
            ),
          ),
          Positioned(
            left: 8,
            bottom: 8,
            child: Container(
              height: 10,
              width: labelWidth,
              decoration: BoxDecoration(
                color: _skeletonColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
