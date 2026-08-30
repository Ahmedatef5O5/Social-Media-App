class ReactionEntry {
  final String userId;
  final String userName;
  final String? userImageUrl;
  final DateTime? lastSeen;
  final String emoji;
  final String? createdAt;

  const ReactionEntry({
    required this.userId,
    required this.userName,
    this.userImageUrl,
    this.lastSeen,
    required this.emoji,
    this.createdAt,
  });
}
