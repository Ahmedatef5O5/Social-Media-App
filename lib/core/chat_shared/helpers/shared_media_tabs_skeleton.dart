import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:shimmer/shimmer.dart';

class GridMediaSkeleton extends StatelessWidget {
  const GridMediaSkeleton({super.key});

  Widget _buildGrid(int count) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => Container(color: Colors.white),
          childCount: count,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          _buildShimmerSectionHeader(70),
          _buildGrid(6),
          _buildShimmerSectionHeader(140),
          _buildGrid(9),
          _buildShimmerSectionHeader(100),
          _buildGrid(6),
        ],
      ),
    );
  }
}

class VoiceListSkeleton extends StatelessWidget {
  const VoiceListSkeleton({super.key});

  Widget _buildVoiceList(int count) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const Gap(10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const Gap(8),
                    Container(
                      width: double.infinity,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        childCount: count,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          _buildShimmerSectionHeader(80),
          _buildVoiceList(3),
          _buildShimmerSectionHeader(130),
          _buildVoiceList(5),
        ],
      ),
    );
  }
}

class LinksListSkeleton extends StatelessWidget {
  const LinksListSkeleton({super.key});

  Widget _buildLinksList(int count) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 160,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Gap(8),
              Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ],
          ),
        ),
        childCount: count,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          _buildShimmerSectionHeader(75),
          _buildLinksList(2),
          _buildShimmerSectionHeader(125),
          _buildLinksList(2),
        ],
      ),
    );
  }
}

Widget _buildShimmerSectionHeader(double width) {
  return SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: width,
          height: 14,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    ),
  );
}
