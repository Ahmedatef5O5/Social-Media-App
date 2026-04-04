import 'package:flutter/material.dart';
import 'package:social_media_app/features/home/models/post_model.dart';
import 'package:social_media_app/features/home/widgets/comment_widget.dart';
import '../../../core/constants/app_images.dart';
import '../../chats/widgets/empty_placeholder_state.dart';

class CommentsSection extends StatelessWidget {
  const CommentsSection({super.key, required this.post});

  final PostModel post;

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
