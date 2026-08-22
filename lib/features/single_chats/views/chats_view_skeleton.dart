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
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 50),

            // ───── Header Skeleton (Messages Text + 2 Icons) ─────
            Row(
              children: [
                Container(width: 120, height: 27, decoration: _box()),
                const Spacer(),
                Container(width: 26, height: 26, decoration: _circle()),
                const SizedBox(width: 16),
                Container(width: 26, height: 26, decoration: _circle()),
              ],
            ),

            const SizedBox(height: 18),

            // ───── Tabs Skeleton (All, Chats, Groups, Favorites) ─────
            Row(
              children: [
                Expanded(
                  flex: 85,
                  child: Container(height: 36, decoration: _box(radius: 20)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 92,
                  child: Container(height: 36, decoration: _box(radius: 20)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 92,
                  child: Container(height: 36, decoration: _box(radius: 20)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 85,
                  child: Container(height: 36, decoration: _box(radius: 20)),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ───── Chats List Skeleton ─────
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 8,
                separatorBuilder:
                    (_, __) => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: Colors.white, height: 1),
                    ),
                itemBuilder: (_, __) => _ChatTileSkeleton(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static BoxDecoration _box({double radius = 8}) => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
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
          width: 54,
          height: 54,
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
                width: MediaQuery.of(context).size.width * 0.35,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: MediaQuery.of(context).size.width * 0.55,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),

        // Time
        Container(
          width: 30,
          height: 10,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}
