import 'package:flutter/material.dart';
import '../models/comment_model.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/design/tokens/typography.dart';

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
                  style: TextStyle(
                    fontSize: 12,
                    inherit: false,
                    fontFamilyFallback: AppTypography.emojiFontFallback,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
