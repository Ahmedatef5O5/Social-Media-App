import 'package:flutter/material.dart';

class GroupReactionsRow extends StatelessWidget {
  final Map<String, String> reactions;
  final String currentUserId;
  final Color primary;

  const GroupReactionsRow({
    super.key,
    required this.reactions,
    required this.currentUserId,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();

    final Map<String, int> counts = {};
    for (final emoji in reactions.values) {
      counts[emoji] = (counts[emoji] ?? 0) + 1;
    }
    final myEmoji = reactions[currentUserId];

    final sorted =
        counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children:
          sorted.map((entry) {
            final emoji = entry.key;
            final count = entry.value;
            final isMine = myEmoji == emoji;

            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _GroupReactionChip(
                emoji: emoji,
                count: count,
                isMine: isMine,
                primary: primary,
              ),
            );
          }).toList(),
    );
  }
}

class _GroupReactionChip extends StatelessWidget {
  final String emoji;
  final int count;
  final bool isMine;
  final Color primary;

  const _GroupReactionChip({
    required this.emoji,
    required this.count,
    required this.isMine,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: count > 1 ? 6.8 : 4,
        vertical: count > 1 ? 3 : 2.8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).scaffoldBackgroundColor.withValues(alpha: 0.75),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.20),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),

      child: Padding(
        padding: EdgeInsets.all(count > 1 ? 3.1 : 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (count > 1) ...[
              const SizedBox(width: 1.9),

              Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isMine ? primary : scheme.onSurfaceVariant,
                  height: 1.2,
                ),
              ),
              const SizedBox(width: 1.5),
            ],

            Text(
              emoji,
              style: TextStyle(
                fontSize: count > 1 ? 9 : 11,
                height: 1.2,
                color: Colors.black,
              ),
            ),

            count > 1 ? const SizedBox(width: 1.2) : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
