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
            Container(
              height: MediaQuery.sizeOf(context).height * 0.18,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
              child: buildShimmer(
                child: Column(
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 20,
                          backgroundColor: skeletonColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 38,
                            decoration: BoxDecoration(
                              color: skeletonColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const SizedBox(height: 14),
                    Container(
                      height: 1,
                      width: double.infinity,
                      color: skeletonColor,
                    ),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        3,
                        (index) => Row(
                          children: [
                            const CircleAvatar(
                              radius: 10,
                              backgroundColor: skeletonColor,
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 50,
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // 3. --- Stories Section ---
            Container(
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
              height: 112,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: buildShimmer(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 5,
                  itemBuilder:
                      (_, index) => Padding(
                        padding: EdgeInsets.only(
                          left: index == 0 ? 16 : 12,
                          right: index == 4 ? 16 : 12,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 55,
                              height: 55,
                              decoration: const BoxDecoration(
                                color: skeletonColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 45,
                              height: 8,
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
                                    Container(
                                      width: screenWidth * 0.15,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: skeletonColor,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Container(
                                    width: 16,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: skeletonColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
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
