import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/mentions/models/mention_ref.dart';
import 'comment_type.dart';

class CommentModel {
  final String id;
  final String createdAt;
  final String authorId;
  final String text;
  final String? authorName;
  final String? authorImageUrl;
  final String postId;
  final CommentType commentType;
  final String? imageUrl;
  final String? videoUrl;
  final String? voiceUrl;
  final String? fileUrl;
  final String? fileName;
  final int? fileSizeBytes;
  final int? durationSeconds;
  final String? imagePublicId;
  final String? videoPublicId;
  final String? voicePublicId;
  final String? filePublicId;
  final int replyCount;
  final int reactionCount;
  final String? parentCommentId;
  final List<CommentModel> replies;
  final List<CommentReaction> reactions;
  final List<MentionRef> mentions;

  const CommentModel({
    required this.id,
    required this.createdAt,
    required this.authorId,
    required this.text,
    this.authorName,
    this.authorImageUrl,
    required this.postId,
    this.commentType = CommentType.text,
    this.imageUrl,
    this.videoUrl,
    this.voiceUrl,
    this.fileUrl,
    this.fileName,
    this.fileSizeBytes,
    this.durationSeconds,
    this.imagePublicId,
    this.videoPublicId,
    this.voicePublicId,
    this.filePublicId,
    this.replyCount = 0,
    this.reactionCount = 0,
    this.parentCommentId,
    this.replies = const [],
    this.reactions = const [],
    this.mentions = const [],
  });

  bool get isReply => parentCommentId != null;
  int get totalReactions => reactions.fold(0, (sum, r) => sum + r.count);
  bool get hasMedia => commentType != CommentType.text;
  bool get hasMentions => mentions.isNotEmpty;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'created_at': createdAt,
      'author_id': authorId,
      'text': text,
      'authorName': authorName,
      'authorImageUrl': authorImageUrl,
      'post_id': postId,
      'comment_type': commentType.value,
      'image_url': imageUrl,
      'video_url': videoUrl,
      'voice_url': voiceUrl,
      'file_url': fileUrl,
      'file_name': fileName,
      'file_size_bytes': fileSizeBytes,
      'duration_seconds': durationSeconds,
      'parent_comment_id': parentCommentId,
    };
  }

  factory CommentModel.fromMap(Map<String, dynamic> map) {
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

    final List<MentionRef> mentions =
        map['comment_mentions'] != null
            ? (map['comment_mentions'] as List<dynamic>)
                .map((m) => MentionRef.fromMap(m as Map<String, dynamic>))
                .toList()
            : [];

    return CommentModel(
      id: map['id'] as String,
      createdAt: map['created_at'] as String,
      authorId: map['author_id'] as String,
      text: map['text'] as String? ?? '',
      authorName: authorName,
      authorImageUrl: authorImageUrl,
      postId: map['post_id'] as String,
      commentType: commentTypeFromString(map['comment_type'] as String?),
      imageUrl: map['image_url'] as String?,
      videoUrl: map['video_url'] as String?,
      voiceUrl: map['voice_url'] as String?,
      fileUrl: map['file_url'] as String?,
      fileName: map['file_name'] as String?,
      fileSizeBytes: map['file_size_bytes'] as int?,
      durationSeconds: map['duration_seconds'] as int?,
      imagePublicId: map['image_public_id'] as String?,
      videoPublicId: map['video_public_id'] as String?,
      voicePublicId: map['voice_public_id'] as String?,
      filePublicId: map['file_public_id'] as String?,
      replyCount: map['reply_count'] as int? ?? 0,
      reactionCount: map['reaction_count'] as int? ?? 0,
      parentCommentId: map['parent_comment_id'] as String?,
      replies: replies,
      reactions: reactions,
      mentions: mentions,
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
    CommentType? commentType,
    String? imageUrl,
    String? videoUrl,
    String? voiceUrl,
    String? fileUrl,
    String? fileName,
    int? fileSizeBytes,
    int? durationSeconds,
    String? imagePublicId,
    String? videoPublicId,
    String? voicePublicId,
    String? filePublicId,
    int? replyCount,
    int? reactionCount,
    String? parentCommentId,
    List<CommentModel>? replies,
    List<CommentReaction>? reactions,
    List<MentionRef>? mentions,
  }) {
    return CommentModel(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      authorId: authorId ?? this.authorId,
      text: text ?? this.text,
      authorName: authorName ?? this.authorName,
      authorImageUrl: authorImageUrl ?? this.authorImageUrl,
      postId: postId ?? this.postId,
      commentType: commentType ?? this.commentType,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      voiceUrl: voiceUrl ?? this.voiceUrl,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      imagePublicId: imagePublicId ?? this.imagePublicId,
      videoPublicId: videoPublicId ?? this.videoPublicId,
      voicePublicId: voicePublicId ?? this.voicePublicId,
      filePublicId: filePublicId ?? this.filePublicId,
      replyCount: replyCount ?? this.replyCount,
      reactionCount: reactionCount ?? this.reactionCount,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      replies: replies ?? this.replies,
      reactions: reactions ?? this.reactions,
      mentions: mentions ?? this.mentions,
    );
  }

  Map<String, dynamic> toCacheJson() => {
    'id': id,
    'created_at': createdAt,
    'author_id': authorId,
    'text': text,
    'author_name': authorName,
    'author_image_url': authorImageUrl,
    'post_id': postId,
    'comment_type': commentType.value,
    'image_url': imageUrl,
    'video_url': videoUrl,
    'voice_url': voiceUrl,
    'file_url': fileUrl,
    'file_name': fileName,
    'file_size_bytes': fileSizeBytes,
    'duration_seconds': durationSeconds,
    'image_public_id': imagePublicId,
    'video_public_id': videoPublicId,
    'voice_public_id': voicePublicId,
    'file_public_id': filePublicId,
    'reply_count': replyCount,
    'reaction_count': reactionCount,
    'parent_comment_id': parentCommentId,
    'replies': replies.map((reply) => reply.toCacheJson()).toList(),
    'reactions': reactions.map((reaction) => reaction.toMap()).toList(),
    'mentions': mentions.map((mention) => mention.toCacheJson()).toList(),
  };

  factory CommentModel.fromCacheJson(Map<String, dynamic> map) {
    return CommentModel(
      id: map['id'] as String,
      createdAt: map['created_at'] as String,
      authorId: map['author_id'] as String,
      text: map['text'] as String? ?? '',
      authorName: map['author_name'] as String?,
      authorImageUrl: map['author_image_url'] as String?,
      postId: map['post_id'] as String,
      commentType: commentTypeFromString(map['comment_type'] as String?),
      imageUrl: map['image_url'] as String?,
      videoUrl: map['video_url'] as String?,
      voiceUrl: map['voice_url'] as String?,
      fileUrl: map['file_url'] as String?,
      fileName: map['file_name'] as String?,
      fileSizeBytes: map['file_size_bytes'] as int?,
      durationSeconds: map['duration_seconds'] as int?,
      imagePublicId: map['image_public_id'] as String?,
      videoPublicId: map['video_public_id'] as String?,
      voicePublicId: map['voice_public_id'] as String?,
      filePublicId: map['file_public_id'] as String?,
      replyCount: map['reply_count'] as int? ?? 0,
      reactionCount: map['reaction_count'] as int? ?? 0,
      parentCommentId: map['parent_comment_id'] as String?,
      replies:
          (map['replies'] as List<dynamic>? ?? [])
              .map(
                (reply) =>
                    CommentModel.fromCacheJson(reply as Map<String, dynamic>),
              )
              .toList(),
      reactions:
          (map['reactions'] as List<dynamic>? ?? [])
              .map(
                (reaction) =>
                    CommentReaction.fromMap(reaction as Map<String, dynamic>),
              )
              .toList(),
      mentions:
          (map['mentions'] as List<dynamic>? ?? [])
              .map(
                (mention) =>
                    MentionRef.fromCacheJson(mention as Map<String, dynamic>),
              )
              .toList(),
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
