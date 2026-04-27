import 'package:flutter/material.dart';
import '../model/comment_model.dart';
import '../../../core/themes/app_colors.dart';

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
    if (reactions.isEmpty) return const SizedBox.shrink();

    final total = reactions.fold<int>(0, (s, r) => s + r.count);

    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 5),
          Text(
            '$total',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: AppColors.grey6,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 3),
          ...reactions
              .take(3)
              .map(
                (r) => Text(
                  r.emoji,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        offset: const Offset(0, 0.5),
                        blurRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
