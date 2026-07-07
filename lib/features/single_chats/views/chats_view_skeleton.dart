import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ChatsViewSkeleton extends StatelessWidget {
  const ChatsViewSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlightColor = isDark ? Colors.grey.shade700 : Colors.grey.shade100;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 50),

            // ───── Header Skeleton ─────
            Row(
              children: [
                Container(width: 90, height: 22, decoration: _box()),
                const Spacer(),
                Container(width: 26, height: 26, decoration: _circle()),
              ],
            ),

            const SizedBox(height: 18),

            // ───── Tabs Skeleton ─────
            Row(
              children: [
                Expanded(child: Container(height: 36, decoration: _box())),
                const SizedBox(width: 12),
                Expanded(child: Container(height: 36, decoration: _box())),
              ],
            ),

            const SizedBox(height: 20),

            // ───── Chats List Skeleton ─────
            Expanded(
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 8,
                separatorBuilder: (_, __) => const SizedBox(height: 18),
                itemBuilder: (_, __) => _ChatTileSkeleton(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static BoxDecoration _box() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
  );

  static BoxDecoration _circle() =>
      const BoxDecoration(color: Colors.white, shape: BoxShape.circle);
}

class _ChatTileSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 14),

        // Texts
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: MediaQuery.of(context).size.width * 0.45,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
