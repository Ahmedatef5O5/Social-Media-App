import 'package:flutter/material.dart';
import 'package:social_media_app/features/home/models/post_model.dart';
import 'package:social_media_app/features/comments/widget/comment_widget.dart';
import '../../../core/constants/app_images.dart';
import '../../chats/widgets/empty_placeholder_state.dart';

class CommentsSection extends StatelessWidget {
  final PostModel post;
  final void Function(String commentId, String authorName)? onReplyTap;

  const CommentsSection({super.key, required this.post, this.onReplyTap});

  @override
  Widget build(BuildContext context) {
    if (post.comments == null || post.comments!.isEmpty) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.45,
        child: EmptyPlaceholderState(
          img: AppImages.smileFaceLot,
          imgHeight: MediaQuery.of(context).size.height * 0.2,
          title: 'No comments yet.',
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      );
    }
    final topLevel =
        post.comments!.where((c) => c.parentCommentId == null).toList();

    return ListView.separated(
      itemCount: topLevel.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final comment = topLevel[index];
        return CommentWidget(
          comment: comment,
          postId: post.id,
          depth: 0,
          onReplyTap: onReplyTap,
        );
      },
    );
  }
}
