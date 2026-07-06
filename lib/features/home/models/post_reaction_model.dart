import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utilities/supabase_constants.dart';

class PostReactionModel {
  final String emoji;
  final int count;
  final bool reactedByMe;

  const PostReactionModel({
    required this.emoji,
    required this.count,
    this.reactedByMe = false,
  });

  PostReactionModel copyWith({String? emoji, int? count, bool? reactedByMe}) {
    return PostReactionModel(
      emoji: emoji ?? this.emoji,
      count: count ?? this.count,
      reactedByMe: reactedByMe ?? this.reactedByMe,
    );
  }

  Map<String, dynamic> toMap() => {
    'emoji': emoji,
    'count': count,
    'reacted_by_me': reactedByMe,
  };

  factory PostReactionModel.fromMap(Map<String, dynamic> map) =>
      PostReactionModel(
        emoji: map['emoji'] as String,
        count: map['count'] as int? ?? 0,
        reactedByMe: map['reacted_by_me'] as bool? ?? false,
      );
}

List<PostReactionModel> parsePostReactions(List<dynamic> rows) {
  final Map<String, int> counts = {};
  final currentUserId = Supabase.instance.client.auth.currentUser?.id;
  String? myEmoji;

  for (final row in rows) {
    final map = row as Map<String, dynamic>;
    final emoji = (map[LikeColumns.reaction] as String?) ?? 'like';
    counts[emoji] = (counts[emoji] ?? 0) + 1;
    if (map[LikeColumns.userId] == currentUserId) {
      myEmoji = emoji;
    }
  }

  final list =
      counts.entries.map((e) {
        return PostReactionModel(
          emoji: e.key,
          count: e.value,
          reactedByMe: myEmoji == e.key,
        );
      }).toList();

  list.sort((a, b) => b.count.compareTo(a.count));
  return list;
}

String reactionGlyph(String value) => value == 'like' ? '👍' : value;
