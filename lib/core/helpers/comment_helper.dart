import '../../features/home/models/comment_model.dart';
import '../../features/comments/widget/comment_constants.dart';

int countAllComments(List<CommentModel>? comments) {
  if (comments == null || comments.isEmpty) return 0;

  int total = 0;

  for (final comment in comments) {
    total += 1;
    if (comment.replies.isNotEmpty) {
      total += countAllComments(comment.replies);
    }
  }

  return total;
}

double avatarDiameter(int depth) => (kAvatarDiameterBase - depth * 4).clamp(
  kAvatarDiameterMin,
  kAvatarDiameterBase,
);

double avatarRadius(int depth) => avatarDiameter(depth) / 2;
