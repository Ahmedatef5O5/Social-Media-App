import 'package:social_media_app/core/utilities/supabase_constants.dart';
import 'package:social_media_app/features/single_chats/models/chat_user_model.dart';
import 'package:social_media_app/features/posts/model/post_reaction_model.dart';
import '../../comments/model/comment_model.dart';

class PostModel {
  bool isLikedBy(String userId) => likes?.contains(userId) ?? false;
  int get likesCount => likes?.length ?? 0;

  String? get myReactionEmoji {
    for (final r in reactions) {
      if (r.reactedByMe) return r.emoji;
    }
    return null;
  }

  String get reactionsSignature =>
      reactions.map((r) => '${r.emoji}:${r.count}').join(',');

  final String id;
  final String text;
  final String authorId;
  final String createdAt;
  final String? authorName;
  final String? authorImageUrl;
  final String? videoUrl;
  final String? fileUrl;
  final String? imageUrl;
  final List<String>? likes;
  final List<String>? likersImages;
  final List<PostReactionModel> reactions;
  final List<CommentModel>? comments;
  final List<String>? shares;
  final DateTime? lastSeen;
  final bool isOnline;

  const PostModel({
    required this.id,
    required this.text,
    required this.authorId,
    required this.createdAt,
    this.authorName,
    this.authorImageUrl,
    this.videoUrl,
    this.fileUrl,
    this.imageUrl,
    this.likes,
    this.likersImages,
    this.reactions = const [],
    this.comments,
    this.shares,
    this.lastSeen,
    this.isOnline = false,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'text': text,
      'authorId': authorId,
      'createdAt': createdAt,
      'authorName': authorName,
      'author_image_url': authorImageUrl,
      'videoUrl': videoUrl,
      'fileUrl': fileUrl,
      'imageUrl': imageUrl,
      'likes': likes,
      'likers_images': likersImages,
      'comments': comments,
      'shares': shares,
      UserColumns.lastSeen: lastSeen,
    };
  }

  ChatUserModel toChatUserModel() {
    return ChatUserModel(
      id: authorId,
      name: authorName ?? 'Unknown User',
      imageUrl: authorImageUrl,
      lastSeen: lastSeen,
      isOnline: isOnline,
    );
  }

  factory PostModel.fromMap(Map<String, dynamic> map) {
    final userData = map[SupabaseConstants.users] as Map<String, dynamic>?;
    final commentsData = map[SupabaseConstants.comments] as List<dynamic>?;
    List<String> likesList = [];
    List<String> imagesList = [];
    List<PostReactionModel> reactionsList = [];
    if (map[SupabaseConstants.likes] != null) {
      final likesData = map[SupabaseConstants.likes] as List<dynamic>;
      for (var item in likesData) {
        likesList.add(item[GroupMemberColumns.userId].toString());
        if (item['users'] != null && item['users']['image_url'] != null) {
          imagesList.add(item['users']['image_url'].toString());
        }
      }
      reactionsList = parsePostReactions(likesData);
    }
    return PostModel(
      id: map['id'] as String? ?? '',
      text: map[PostColumns.text] as String? ?? '',
      authorId: map[PostColumns.authorId] as String? ?? '',
      createdAt: map[PostColumns.createdAt] as String? ?? '',
      authorName:
          userData != null
              ? userData[UserColumns.name] as String? ?? 'Unknown User'
              : null,
      authorImageUrl:
          userData != null ? userData[UserColumns.imageUrl] as String? : null,
      videoUrl:
          map['video_url'] != null ? map['video_url'] as String? ?? '' : null,
      imageUrl: map['image_url'] != null ? map['image_url'] as String : null,
      fileUrl: map['file_url'] != null ? map['file_url'] as String : null,

      likes: likesList,
      likersImages: imagesList,
      reactions: reactionsList,
      comments:
          commentsData != null
              ? commentsData.map((c) => CommentModel.fromMap(c)).toList()
              : [],
      shares:
          map[PostColumns.shares] != null
              ? List<String>.from(map[PostColumns.shares])
              : [],
      lastSeen:
          userData != null && userData[UserColumns.lastSeen] != null
              ? DateTime.parse(userData[UserColumns.lastSeen].toString())
              : null,
      isOnline: false,
    );
  }

  PostModel copyWith({
    String? id,
    String? text,
    String? authorId,
    String? createdAt,
    String? authorName,
    String? authorImageUrl,
    String? videoUrl,
    String? fileUrl,
    String? imageUrl,
    List<String>? likes,
    List<String>? likersImages,
    List<PostReactionModel>? reactions,
    List<CommentModel>? comments,
    List<String>? shares,
    final DateTime? lastSeen,
    final bool? isOnline,
  }) {
    return PostModel(
      id: id ?? this.id,
      text: text ?? this.text,
      authorId: authorId ?? this.authorId,
      createdAt: createdAt ?? this.createdAt,
      authorName: authorName ?? this.authorName,
      authorImageUrl: authorImageUrl ?? this.authorImageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      fileUrl: fileUrl ?? this.fileUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      likes: likes ?? this.likes,
      likersImages: likersImages ?? this.likersImages,
      reactions: reactions ?? this.reactions,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  Map<String, dynamic> toCacheJson() => {
    'id': id,
    'text': text,
    'author_id': authorId,
    'created_at': createdAt,
    'author_name': authorName,
    'author_image_url': authorImageUrl,
    'video_url': videoUrl,
    'file_url': fileUrl,
    'image_url': imageUrl,
    'likes': likes,
    'likers_images': likersImages,
    'reactions': reactions.map((r) => r.toMap()).toList(),
    'comments': comments?.map((comment) => comment.toCacheJson()).toList(),
    'shares': shares,
    'last_seen': lastSeen?.toIso8601String(),
    'is_online': isOnline,
  };

  factory PostModel.fromCacheJson(Map<String, dynamic> map) {
    return PostModel(
      id: map['id'] as String,
      text: map['text'] as String,
      authorId: map['author_id'] as String,
      createdAt: map['created_at'] as String,
      authorName: map['author_name'] as String?,
      authorImageUrl: map['author_image_url'] as String?,
      videoUrl: map['video_url'] as String?,
      fileUrl: map['file_url'] as String?,
      imageUrl: map['image_url'] as String?,
      likes: (map['likes'] as List<dynamic>?)?.cast<String>(),
      likersImages: (map['likers_images'] as List<dynamic>?)?.cast<String>(),
      reactions:
          (map['reactions'] as List<dynamic>? ?? [])
              .map((r) => PostReactionModel.fromMap(r as Map<String, dynamic>))
              .toList(),
      comments:
          (map['comments'] as List<dynamic>?)
              ?.map(
                (comment) =>
                    CommentModel.fromCacheJson(comment as Map<String, dynamic>),
              )
              .toList(),
      shares: (map['shares'] as List<dynamic>?)?.cast<String>(),
      lastSeen:
          map['last_seen'] != null
              ? DateTime.parse(map['last_seen'] as String)
              : null,
      isOnline: map['is_online'] as bool? ?? false,
    );
  }
}
