class MentionSuggestion {
  final String userId;
  final String name;
  final String? imageUrl;

  const MentionSuggestion({
    required this.userId,
    required this.name,
    this.imageUrl,
  });
}
