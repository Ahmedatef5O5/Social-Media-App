class CommentTypingUser {
  final String id;
  final String name;
  final String? imageUrl;

  const CommentTypingUser({
    required this.id,
    required this.name,
    this.imageUrl,
  });
}
