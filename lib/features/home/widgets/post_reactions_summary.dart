import 'package:flutter/material.dart';
import '../models/post_reaction_model.dart';

class PostReactionsSummary extends StatelessWidget {
  final List<PostReactionModel> reactions;

  const PostReactionsSummary({super.key, required this.reactions});

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();

    final sorted = List<PostReactionModel>.from(reactions)
      ..sort((a, b) => b.count.compareTo(a.count));
    final total = sorted.fold<int>(0, (s, r) => s + r.count);
    final top = sorted.take(3).toList();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$total', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(width: 6),
        SizedBox(
          height: 20,
          width: 16.0 + (top.length - 1) * 12.0,
          child: Stack(
            clipBehavior: Clip.none,
            children:
                List.generate(top.length, (i) {
                  return Positioned(
                    left: i * 12.0,
                    child: Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).scaffoldBackgroundColor,
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: Text(
                        reactionGlyph(top[i].emoji),
                        style: const TextStyle(fontSize: 11, height: 1),
                      ),
                    ),
                  );
                }).reversed.toList(),
          ),
        ),
      ],
    );
  }
}
