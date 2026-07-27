import 'package:social_media_app/core/utilities/supabase_constants.dart';
import 'package:social_media_app/features/single_chats/models/chat_user_model.dart';
import 'package:social_media_app/features/posts/model/post_reaction_model.dart';
import '../../../core/mentions/models/mention_ref.dart';
import '../../comments/model/comment_model.dart';
import '../../reels/model/reel_model.dart';
import '../../social_graph/models/content_privacy.dart';

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

  bool get isSharedPost => sharedPostId != null;
  bool get isSharedReel => sharedReelId != null;

  PostModel get displayPost =>
      (isSharedPost && originalPost != null) ? originalPost! : this;

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
  final List<MentionRef> mentions;
  final List<CommentModel>? comments;
  final DateTime? lastSeen;
  final bool isOnline;
  final int savedCount;
  final bool isSavedByMe;

  // ── Shared Post feature ──────────────────────────────────────────────
  final String? sharedPostId;
  final PostModel? originalPost;
  final int sharesCount;
  final bool isSharedByMe;

  // ── Shared Reel feature ──────────────────────────────────────────────
  final String? sharedReelId;
  final ReelModel? sharedReel;

  // - Privacy publishing
  final ContentPrivacy privacyType;

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
    this.mentions = const [],
    this.comments,
    this.lastSeen,
    this.isOnline = false,
    this.savedCount = 0,
    this.isSavedByMe = false,
    this.sharedPostId,
    this.originalPost,
    this.sharesCount = 0,
    this.isSharedByMe = false,
    this.sharedReelId,
    this.sharedReel,
    this.privacyType = ContentPrivacy.public,
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
      PostColumns.privacyType: contentPrivacyToString(privacyType),
      PostColumns.sharedPostId: sharedPostId,
      PostColumns.sharedReelId: sharedReelId,
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
    final List<MentionRef> mentions =
        map['post_mentions'] != null
            ? (map['post_mentions'] as List<dynamic>)
                .map((m) => MentionRef.fromMap(m as Map<String, dynamic>))
                .toList()
            : [];
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

    final originalPostData =
        map[PostColumns.originalPostRelation] as Map<String, dynamic>?;

    final sharedReelData =
        map[SupabaseConstants.reelsCache] as Map<String, dynamic>?;

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
      mentions: mentions,
      comments:
          commentsData != null
              ? commentsData.map((c) => CommentModel.fromMap(c)).toList()
              : [],
      lastSeen:
          userData != null && userData[UserColumns.lastSeen] != null
              ? DateTime.parse(userData[UserColumns.lastSeen].toString())
              : null,
      isOnline: false,
      savedCount: map['saved_count'] as int? ?? 0,
      isSavedByMe: map['is_post_saved'] as bool? ?? false,
      sharedPostId: map[PostColumns.sharedPostId] as String?,
      originalPost:
          originalPostData != null ? PostModel.fromMap(originalPostData) : null,
      sharesCount: map['shares_count'] as int? ?? 0,
      isSharedByMe: map['is_post_shared'] as bool? ?? false,
      sharedReelId: map[PostColumns.sharedReelId] as String?,
      sharedReel:
          sharedReelData != null ? ReelModel.fromMap(sharedReelData) : null,
      privacyType: contentPrivacyFromString(
        map[PostColumns.privacyType] as String?,
      ),
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
    List<MentionRef>? mentions,
    List<CommentModel>? comments,
    final DateTime? lastSeen,
    final bool? isOnline,
    final int? savedCount,
    final bool? isSavedByMe,
    String? sharedPostId,
    PostModel? originalPost,
    int? sharesCount,
    bool? isSharedByMe,
    String? sharedReelId,
    ReelModel? sharedReel,
    ContentPrivacy? privacyType,
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
      mentions: mentions ?? this.mentions,
      comments: comments ?? this.comments,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
      savedCount: savedCount ?? this.savedCount,
      isSavedByMe: isSavedByMe ?? this.isSavedByMe,
      sharedPostId: sharedPostId ?? this.sharedPostId,
      originalPost: originalPost ?? this.originalPost,
      sharesCount: sharesCount ?? this.sharesCount,
      isSharedByMe: isSharedByMe ?? this.isSharedByMe,
      sharedReelId: sharedReelId ?? this.sharedReelId,
      sharedReel: sharedReel ?? this.sharedReel,
      privacyType: privacyType ?? this.privacyType,
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
    'mentions': mentions.map((m) => m.toCacheJson()).toList(),
    'comments': comments?.map((comment) => comment.toCacheJson()).toList(),
    'last_seen': lastSeen?.toIso8601String(),
    'is_online': isOnline,
    'saved_count': savedCount,
    'is_post_saved': isSavedByMe,
    'shared_post_id': sharedPostId,
    'original_post': originalPost?.toCacheJson(),
    'shares_count': sharesCount,
    'is_post_shared': isSharedByMe,
    'shared_reel_id': sharedReelId,
    'shared_reel': sharedReel?.toJson(),
    PostColumns.privacyType: contentPrivacyToString(privacyType),
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
      mentions:
          (map['mentions'] as List<dynamic>? ?? [])
              .map((m) => MentionRef.fromCacheJson(m as Map<String, dynamic>))
              .toList(),
      comments:
          (map['comments'] as List<dynamic>?)
              ?.map(
                (comment) =>
                    CommentModel.fromCacheJson(comment as Map<String, dynamic>),
              )
              .toList(),
      lastSeen:
          map['last_seen'] != null
              ? DateTime.parse(map['last_seen'] as String)
              : null,
      isOnline: map['is_online'] as bool? ?? false,
      savedCount: map['saved_count'] as int? ?? 0,
      isSavedByMe: map['is_post_saved'] as bool? ?? false,
      sharedPostId: map['shared_post_id'] as String?,
      originalPost:
          map['original_post'] != null
              ? PostModel.fromCacheJson(
                map['original_post'] as Map<String, dynamic>,
              )
              : null,
      sharesCount: map['shares_count'] as int? ?? 0,
      isSharedByMe: map['is_post_shared'] as bool? ?? false,
      sharedReelId: map['shared_reel_id'] as String?,
      sharedReel:
          map['shared_reel'] != null
              ? ReelModel.fromJson(map['shared_reel'] as Map<String, dynamic>)
              : null,
      privacyType: contentPrivacyFromString(
        map[PostColumns.privacyType] as String?,
      ),
    );
  }
}

extension PostListLookup on List<PostModel> {
  PostModel? findById(String id) {
    for (final p in this) {
      if (p.id == id) return p;
      if (p.originalPost?.id == id) return p.originalPost;
    }
    return null;
  }
}

extension PostListUpdater on List<PostModel> {
  List<PostModel> updatePostById(
    String targetId,
    PostModel Function(PostModel current) transform,
  ) {
    return map((p) {
      if (p.id == targetId) return transform(p);
      if (p.originalPost?.id == targetId) {
        return p.copyWith(originalPost: transform(p.originalPost!));
      }
      return p;
    }).toList();
  }
}
