import 'package:flutter/material.dart';
import 'package:social_media_app/features/home/models/comment_model.dart';
import '../../../core/themes/app_colors.dart';

class CommentWidget extends StatelessWidget {
  final CommentModel comment;
  final String postId;

  const CommentWidget({super.key, required this.comment, required this.postId});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundImage:
              comment.authorImageUrl != null
                  ? NetworkImage(comment.authorImageUrl!)
                  : null,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.bgColor2,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comment.authorName ?? '',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comment.text,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.reply),
          onPressed: () {
            // Handle reply action
          },
        ),
      ],
    );
  }
}
