class StoryReactorModel {
  final String userId;
  final String userName;
  final String? userImageUrl;
  final String reaction;

  const StoryReactorModel({
    required this.userId,
    required this.userName,
    this.userImageUrl,
    required this.reaction,
  });

  factory StoryReactorModel.fromMap(Map<String, dynamic> map) {
    return StoryReactorModel(
      userId: map['user_id'] as String? ?? '',
      userName: map['user_name'] as String? ?? 'Unknown',
      userImageUrl: map['user_image_url'] as String?,
      reaction: map['reaction'] as String? ?? '',
    );
  }
}

class StoryStatModel {
  final String storyId;
  final int viewCount;
  final int reactionCount;
  final List<StoryReactorModel> reactions;

  const StoryStatModel({
    required this.storyId,
    required this.viewCount,
    required this.reactionCount,
    required this.reactions,
  });

  factory StoryStatModel.fromMap(Map<String, dynamic> map) {
    final reactionsRaw = map['reactions'] as List<dynamic>? ?? const [];
    return StoryStatModel(
      storyId: map['story_id'] as String? ?? '',
      viewCount: (map['view_count'] as num?)?.toInt() ?? 0,
      reactionCount: (map['reaction_count'] as num?)?.toInt() ?? 0,
      reactions:
          reactionsRaw
              .map((e) => StoryReactorModel.fromMap(e as Map<String, dynamic>))
              .toList(),
    );
  }
}
