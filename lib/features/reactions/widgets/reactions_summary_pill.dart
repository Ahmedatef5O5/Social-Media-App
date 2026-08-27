import 'package:flutter/material.dart';
import '../../../core/design/tokens/typography.dart';

class ReactionsSummaryPill extends StatelessWidget {
  final Map<String, String> reactions;
  final String currentUserId;
  final Color primary;

  final VoidCallback? onTap;

  const ReactionsSummaryPill({
    super.key,
    required this.reactions,
    required this.currentUserId,
    required this.primary,
    this.onTap,
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

    const double overlap = 14.0;
    const double emojiSize = 18.0;
    final double stackWidth = (sorted.length - 1) * overlap + emojiSize;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.15),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (reactions.length > 1) ...[
            const SizedBox(width: 1),
            Text(
              '${reactions.length}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color:
                    myEmoji != null
                        ? primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.2,
              ),
            ),
            const SizedBox(width: 1),
          ],
          SizedBox(
            width: stackWidth,
            height: 18,
            child: Stack(
              clipBehavior: Clip.none,
              children: List.generate(sorted.length, (index) {
                final emoji = sorted[index].key;
                final reversedIndex = sorted.length - 1 - index;

                return Positioned(
                  left: reversedIndex * overlap,
                  child: Container(
                    padding: const EdgeInsets.all(2.0),
                    child: Text(
                      emoji,
                      style: TextStyle(
                        inherit: false,
                        fontSize: 12,
                        height: 1.2,
                        fontWeight: FontWeight.normal,
                        fontFamilyFallback: AppTypography.emojiFontFallback,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );

    return Transform.translate(
      offset: const Offset(0, -8),
      child:
          onTap != null
              ? GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: pill,
              )
              : pill,
    );
  }
}
