import 'post_model.dart';

class ProfilePostsPage {
  final List<PostModel> posts;
  final bool hasMore;
  final String? nextCursorCreatedAt;
  final String? nextCursorId;
  final bool? nextCursorIsPinned;

  const ProfilePostsPage({
    required this.posts,
    required this.hasMore,
    this.nextCursorCreatedAt,
    this.nextCursorId,
    this.nextCursorIsPinned,
  });

  static const ProfilePostsPage empty = ProfilePostsPage(
    posts: [],
    hasMore: false,
  );
}
