import '../../home/models/comment_model.dart';

class CommentEvent {
  final String postId;
  final CommentModel comment;
  final String? parentId;
  final String authorName;
  final String authorImageUrl;

  CommentEvent({
    required this.postId,
    required this.comment,
    this.parentId,
    required this.authorName,
    required this.authorImageUrl,
  });
}
