import 'package:flutter/material.dart';
import 'package:social_media_app/features/comments/model/comment_model.dart';
import 'package:social_media_app/features/comments/widget/comment_widget.dart';
import '../../../core/constants/app_images.dart';
import '../../single_chats/widgets/empty_placeholder_state.dart';

class CommentsSection extends StatelessWidget {
  final String postId;
  final String postAuthorId;
  final List<CommentModel> comments;
  final void Function(String commentId, String authorName)? onReplyTap;
  final void Function(CommentModel)? onEditTap;

  const CommentsSection({
    super.key,
    required this.postId,
    required this.postAuthorId,
    required this.comments,
    this.onReplyTap,
    this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    if (comments.isEmpty) {
      return SliverToBoxAdapter(
        child: SizedBox(
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
        ),
      );
    }

    return SliverList.separated(
      itemCount: comments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final comment = comments[index];
        return CommentWidget(
          comment: comment,
          postId: postId,
          postAuthorId: postAuthorId,
          depth: 0,
          onReplyTap: onReplyTap,
          onEditTap: onEditTap,
        );
      },
    );
  }
}
