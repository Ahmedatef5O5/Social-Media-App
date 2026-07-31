import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/widgets/skeleton_shapes.dart';

class DrawerHeaderShimmer extends StatelessWidget {
  const DrawerHeaderShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    const double aspectRatio = 1.8;
    const double avatarSizeFactor = 0.28;

    final double dynamicBackgroundHeight = screenWidth / aspectRatio;
    final double dynamicAvatarSize = screenWidth * avatarSizeFactor;
    final double calculatedTotalHeight =
        dynamicBackgroundHeight + (dynamicAvatarSize / 2);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          children: [
            SizedBox(
              height: calculatedTotalHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  SkeletonBox(
                    height: dynamicBackgroundHeight,
                    width: double.infinity,
                    radius: 0,
                  ),

                  Align(
                    alignment: Alignment.bottomCenter,
                    child: SkeletonCircle(size: dynamicAvatarSize),
                  ),

                  const Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 12,
                      ),
                      child: SkeletonCircle(size: 26),
                    ),
                  ),
                ],
              ),
            ),

            const Gap(12),
            const SkeletonBox(height: 22, width: 140, radius: 4),
            const Gap(8),
            const SkeletonBox(height: 14, width: 90, radius: 4),
          ],
        ),
      ),
    );
  }
}
