import 'post_model.dart';

/// One keyset page of a group's feed.
class GroupPostsPage {
  final List<PostModel> posts;
  final bool hasMore;
  final String? nextCursorCreatedAt;
  final String? nextCursorId;

  const GroupPostsPage({
    required this.posts,
    required this.hasMore,
    this.nextCursorCreatedAt,
    this.nextCursorId,
  });

  static const GroupPostsPage empty = GroupPostsPage(posts: [], hasMore: false);
}
