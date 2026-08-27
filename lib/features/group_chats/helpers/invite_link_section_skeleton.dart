import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class InviteLinkSectionSkeleton extends StatelessWidget {
  const InviteLinkSectionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    Widget bar({
      double width = double.infinity,
      double height = 14,
      double radius = 6,
    }) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
    }

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bar(width: 230, height: 14),
          const SizedBox(height: 8),
          bar(width: 130, height: 12),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: bar(height: 40, radius: 10)),
              const SizedBox(width: 8),
              Expanded(child: bar(height: 40, radius: 10)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              bar(width: 100, height: 24, radius: 20),
              bar(width: 90, height: 14),
            ],
          ),
        ],
      ),
    );
  }
}
