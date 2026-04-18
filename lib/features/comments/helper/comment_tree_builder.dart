import '../model/comment_model.dart';

class CommentTreeBuilder {
  static List<CommentModel> build(List<CommentModel> comments) {
    final map = <String, CommentModel>{};
    final roots = <CommentModel>[];

    for (final c in comments) {
      map[c.id] = c.copyWith(replies: []);
    }

    for (final c in comments) {
      final node = map[c.id]!;

      if (c.parentCommentId == null) {
        roots.add(node);
      } else {
        final parent = map[c.parentCommentId];
        parent?.replies.add(node);
      }
    }

    return roots;
  }
}
