import 'package:flutter/material.dart';

import '../../../core/themes/app_colors.dart';
import '../../home/models/comment_model.dart';

class CommentReactionsSummary extends StatelessWidget {
  final List<CommentReaction> reactions;
  final VoidCallback? onTap;

  const CommentReactionsSummary({
    super.key,
    required this.reactions,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = reactions.where((r) => r.count > 0).toList();
    if (active.isEmpty) return const SizedBox.shrink();

    final total = active.fold<int>(0, (s, r) => s + r.count);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Show up to 3 emoji icons
            ...active
                .take(3)
                .map(
                  (r) => Text(r.emoji, style: const TextStyle(fontSize: 13)),
                ),
            const SizedBox(width: 4),
            Text(
              '$total',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: AppColors.grey7,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
