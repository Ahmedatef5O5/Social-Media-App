class MentionRef {
  final String mentionedUserId;
  final int startIndex;
  final int endIndex;

  const MentionRef({
    required this.mentionedUserId,
    required this.startIndex,
    required this.endIndex,
  });

  factory MentionRef.fromMap(Map<String, dynamic> map) {
    return MentionRef(
      mentionedUserId: map['mentioned_user_id'] as String,
      startIndex: map['start_index'] as int,
      endIndex: map['end_index'] as int,
    );
  }

  Map<String, dynamic> toRpcMap() => {
    'user_id': mentionedUserId,
    'start': startIndex,
    'end': endIndex,
  };

  Map<String, dynamic> toCacheJson() => {
    'mentioned_user_id': mentionedUserId,
    'start_index': startIndex,
    'end_index': endIndex,
  };

  factory MentionRef.fromCacheJson(Map<String, dynamic> map) =>
      MentionRef.fromMap(map);
}
