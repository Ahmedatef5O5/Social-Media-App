import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class StoryShimmerWidget extends StatelessWidget {
  const StoryShimmerWidget({super.key});

  static final _baseColor = Colors.grey[800]!;
  static final _highlightColor = Colors.grey[700]!;
  static const _skeletonColor = Colors.white24;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _baseColor,
      highlightColor: _highlightColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Colors.black),

          Positioned(
            top: 110,
            bottom: 110,
            left: 24,
            right: 24,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _skeletonColor,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),

          Positioned(
            top: 40,
            left: 10,
            right: 10,
            child: Row(
              children: List.generate(
                3,
                (i) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: _skeletonColor,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: 55,
            left: 20,
            right: 20,
            child: Row(
              children: [
                const CircleAvatar(radius: 20, backgroundColor: _skeletonColor),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 90,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _skeletonColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 50,
                      height: 9,
                      decoration: BoxDecoration(
                        color: _skeletonColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: _skeletonColor,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
