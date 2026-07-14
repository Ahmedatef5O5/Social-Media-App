import 'package:flutter/material.dart';

class NotificationsShimmerList extends StatelessWidget {
  final bool isDark;

  const NotificationsShimmerList({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final base =
        isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100;
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 8,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 68),
      itemBuilder:
          (_, __) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(radius: 24, backgroundColor: base),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 12,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: base,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 10,
                        width: 180,
                        decoration: BoxDecoration(
                          color: base,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
