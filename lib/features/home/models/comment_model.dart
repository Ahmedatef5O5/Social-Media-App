import 'package:supabase_flutter/supabase_flutter.dart';

class CommentModel {
  final String id;
  final String createdAt;
  final String authorId;
  final String text;
  final String? authorName;
  final String? authorImageUrl;
  final String postId;
  final String? imageUrl;

  final String? parentCommentId; // null = top-level, non-null = reply
  final List<CommentModel> replies;
  final List<CommentReaction> reactions;

  const CommentModel({
    required this.id,
    required this.createdAt,
    required this.authorId,
    required this.text,
    this.authorName,
    this.authorImageUrl,
    required this.postId,
    this.imageUrl,
    this.parentCommentId,
    this.replies = const [],
    this.reactions = const [],
  });

  bool get isReply => parentCommentId != null;
  int get totalReactions => reactions.fold(0, (sum, r) => sum + r.count);

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'created_at': createdAt,
      'author_id': authorId,
      'text': text,
      'authorName': authorName,
      'authorImageUrl': authorImageUrl,
      'post_id': postId,
      'image': imageUrl,
      'parent_comment_id': parentCommentId,
    };
  }

  factory CommentModel.fromMap(Map<String, dynamic> map) {
    // final userData = map[SupabaseConstants.users] as Map<String, dynamic>?;
    // final repliesData = map['replies'] as List<dynamic>?;
    // final reactionsData = map['reactions'] as List<dynamic>?;
    final authorName = map['users']?['name'] as String?;
    final authorImageUrl = map['users']?['image_url'] as String?;
    final List<CommentModel> replies =
        map['replies'] != null
            ? List<CommentModel>.from(
              (map['replies'] as List).map(
                (x) => CommentModel.fromMap(x as Map<String, dynamic>),
              ),
            )
            : [];

    final List<CommentReaction> reactions =
        map['comment_reactions'] != null
            ? parseReactions(map['comment_reactions'] as List<dynamic>)
            : [];

    return CommentModel(
      id: map['id'] as String,
      createdAt: map['created_at'] as String,
      authorId: map['author_id'] as String,
      text: map['text'] as String,
      authorName: authorName,
      authorImageUrl: authorImageUrl,
      postId: map['post_id'] as String,
      imageUrl: map['image_url'] != null ? map['image_url'] as String : null,
      parentCommentId: map['parent_comment_id'] as String?,
      replies: replies,
      reactions: reactions,
    );
  }

  CommentModel copyWith({
    String? id,
    String? createdAt,
    String? authorId,
    String? text,
    String? authorName,
    String? authorImageUrl,
    String? postId,
    String? imageUrl,
    String? parentCommentId,
    List<CommentModel>? replies,
    List<CommentReaction>? reactions,
  }) {
    return CommentModel(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      authorId: authorId ?? this.authorId,
      text: text ?? this.text,
      authorName: authorName ?? this.authorName,
      authorImageUrl: authorImageUrl ?? this.authorImageUrl,
      postId: postId ?? this.postId,
      imageUrl: imageUrl ?? this.imageUrl,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      replies: replies ?? this.replies,
      reactions: reactions ?? this.reactions,
    );
  }
}

class CommentReaction {
  final String emoji;
  final int count;
  final bool reactedByMe;

  const CommentReaction({
    required this.emoji,
    required this.count,
    this.reactedByMe = false,
  });
  CommentReaction copyWith({String? emoji, int? count, bool? reactedByMe}) {
    return CommentReaction(
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

  factory CommentReaction.fromMap(Map<String, dynamic> map) => CommentReaction(
    emoji: map['emoji'] as String,
    count: map['count'] as int? ?? 0,
    reactedByMe: map['reacted_by_me'] as bool? ?? false,
  );
}

List<CommentReaction> parseReactions(List<dynamic> data) {
  final Map<String, int> counts = {};
  final userId = Supabase.instance.client.auth.currentUser?.id;
  final Set<String> myEmojis = {};

  for (var row in data) {
    String emoji = row['emoji'];
    counts[emoji] = (counts[emoji] ?? 0) + 1;
    if (row['user_id'] == userId) {
      myEmojis.add(emoji);
    }
  }

  return counts.entries.map((e) {
    return CommentReaction(
      emoji: e.key,
      count: e.value,
      reactedByMe: myEmojis.contains(e.key),
    );
  }).toList();
}
