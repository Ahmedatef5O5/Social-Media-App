import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:shimmer/shimmer.dart';

class CreateStickerPackFormSkeleton extends StatelessWidget {
  const CreateStickerPackFormSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    Widget fakeBox({double? width, double? height, double borderRadius = 12}) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      );
    }

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                fakeBox(height: 60, borderRadius: 16),
                const Gap(32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    fakeBox(width: 80, height: 18, borderRadius: 4),
                    fakeBox(width: 100, height: 14, borderRadius: 4),
                  ],
                ),
                const Gap(16),

                Row(
                  children: [
                    fakeBox(width: 75, height: 75, borderRadius: 16),
                    const Gap(12),
                    fakeBox(width: 75, height: 75, borderRadius: 16),
                    const Gap(12),
                    fakeBox(width: 75, height: 75, borderRadius: 16),
                  ],
                ),
                const Gap(40),

                Center(child: fakeBox(width: 140, height: 16, borderRadius: 4)),
                const Gap(16),
                fakeBox(height: 70, borderRadius: 16),
              ],
            ),
          ),

          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            child: fakeBox(height: 56, borderRadius: 28),
          ),
        ],
      ),
    );
  }
}
