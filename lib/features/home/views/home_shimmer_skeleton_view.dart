// ignore_for_file: avoid_unnecessary_containers
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class HomeShimmerSkeleton extends StatelessWidget {
  const HomeShimmerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    final cardBgColor = isDark ? Colors.grey[900]! : Colors.white;
    final scaffoldBgColor = isDark ? Colors.black : Colors.grey[200]!;

    const skeletonColor = Colors.white;

    final screenWidth = MediaQuery.sizeOf(context).width;

    Widget buildShimmer({required Widget child}) {
      return Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: child,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2),
      color: scaffoldBgColor,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
              padding: const EdgeInsets.only(
                top: 40,
                left: 16,
                right: 16,
                bottom: 12,
              ),
              child: buildShimmer(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 130,
                      height: 28,
                      decoration: BoxDecoration(
                        color: skeletonColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: skeletonColor,
                        ),
                        const SizedBox(width: 12),
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: skeletonColor,
                        ),
                        const SizedBox(width: 12),
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: skeletonColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // 2. --- Write Post Card Section ---
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 2.0,
                vertical: 8.0,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: buildShimmer(
                  child: Row(
                    children: [
                      // الـ Avatar
                      Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: skeletonColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 14,
                          decoration: BoxDecoration(
                            color: skeletonColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // مكان الـ AnimatedActionCluster (Icons)
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Transform.translate(
                              // قللنا المسافة هنا عشان الدائرة تقرب للمركز
                              offset: const Offset(-5.5, 4.0),
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: const BoxDecoration(
                                  color: skeletonColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Transform.translate(
                              // قللنا المسافة هنا
                              offset: const Offset(5.5, 4.0),
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: const BoxDecoration(
                                  color: skeletonColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Transform.translate(
                              offset: const Offset(0, -9.50),
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: const BoxDecoration(
                                  color: skeletonColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // 3. --- Stories Section ---
            Container(
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: const BorderRadius.all(Radius.circular(14)),
              ),
              height: 170 + 24,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: buildShimmer(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 5,
                  itemBuilder: (_, index) {
                    final randomWidthFactors = [0.65, 0.75, 0.70, 0.80, 0.62];
                    final textWidth =
                        110 *
                        randomWidthFactors[index % randomWidthFactors.length];

                    return Padding(
                      padding: EdgeInsets.only(
                        left: index == 0 ? 14 : 10,
                        right: index == 4 ? 14 : 10,
                      ),
                      child: Container(
                        width: 110,
                        height: 170,
                        decoration: BoxDecoration(
                          color: skeletonColor.withValues(alpha: 0.15),
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
                                  color: skeletonColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: skeletonColor),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 8,
                              bottom: 8,
                              child: Container(
                                height: 10,
                                width: textWidth,
                                decoration: BoxDecoration(
                                  color: skeletonColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),

            // 4. --- Post Cards Section ---
            ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder:
                  (_, __) => Container(
                    margin: const EdgeInsets.only(bottom: 8),

                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: buildShimmer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Post Header
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const CircleAvatar(
                                  radius: 20,
                                  backgroundColor: skeletonColor,
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: screenWidth * 0.35,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: skeletonColor,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: const BoxDecoration(
                                            color: skeletonColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Container(
                                          width: screenWidth * 0.15,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: skeletonColor,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 14,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: skeletonColor,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Container(
                                        width: 16,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: skeletonColor,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Post Text Content
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: skeletonColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  width: screenWidth * 0.7,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: skeletonColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Post Media
                          Container(
                            height: screenWidth * 0.65,
                            width: double.infinity,
                            color: skeletonColor,
                          ),
                          const SizedBox(height: 12),

                          // Post Stats
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  width: screenWidth * 0.15,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: skeletonColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                Container(
                                  width: screenWidth * 0.25,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: skeletonColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Divider
                          Container(
                            height: 1,
                            width: double.infinity,
                            color: skeletonColor,
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          const SizedBox(height: 10),

                          // Post Actions
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(
                                3,
                                (index) => Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 12,
                                      backgroundColor: skeletonColor,
                                    ),
                                    const SizedBox(width: 8),
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
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
