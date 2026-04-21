import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

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
    // Group same emojis and count them
    final Map<String, int> counts = {};
    for (final emoji in reactions.values) {
      counts[emoji] = (counts[emoji] ?? 0) + 1;
    }

    final myReaction = reactions[currentUserId];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children:
            counts.entries.map((entry) {
              final isMe = myReaction == entry.key;
              return Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(entry.key, style: const TextStyle(fontSize: 14)),
                    if (entry.value > 1) ...[
                      const Gap(2),
                      Text(
                        '${entry.value}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isMe ? primary : Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }
}
