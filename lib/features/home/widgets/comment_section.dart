import 'package:flutter/material.dart';
import 'package:social_media_app/features/home/models/post_model.dart';
import 'package:social_media_app/features/home/widgets/comment_widget.dart';

class CommentsSection extends StatelessWidget {
  const CommentsSection({super.key, required this.post});

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    if (post.comments == null || post.comments!.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text("No comments yet. Be the first to comment!"),
        ),
      );
    }
    return ListView.separated(
      itemCount: post.comments?.length ?? 0,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final comment = post.comments![index];
        return CommentWidget(comment: comment, postId: post.id);
      },
    );
  }
}
