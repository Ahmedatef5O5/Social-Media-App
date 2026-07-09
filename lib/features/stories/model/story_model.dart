import 'package:social_media_app/core/utilities/supabase_constants.dart';
import 'package:social_media_app/features/single_chats/models/chat_user_model.dart';

enum StoryType { image, video, text }

class StoryModel {
  final String id;
  final String? imageUrl;
  final String? videoUrl;
  final String? contentText;
  final String? backgroundColor;
  final String authorId;
  final String authorName;
  final String? authorImageUrl;
  final String createdAt;
  final String? caption;
  final DateTime? lastSeen;

  final String? imagePublicId;
  final String? videoPublicId;
  final int? videoDurationSeconds;

  const StoryModel({
    this.id = '',
    this.imageUrl,
    this.videoUrl,
    this.contentText,
    this.backgroundColor,
    required this.authorId,
    required this.authorName,
    this.authorImageUrl,
    required this.createdAt,
    this.caption,
    this.lastSeen,
    this.imagePublicId,
    this.videoPublicId,
    this.videoDurationSeconds,
  });

  StoryType get storyType {
    if (videoUrl != null) return StoryType.video;
    if (imageUrl != null) return StoryType.image;
    return StoryType.text;
  }

  static const Duration activeWindow = Duration(days: 200);

  bool get isExpired {
    final created = DateTime.tryParse(createdAt);
    if (created == null) return false;
    return DateTime.now().difference(created) > activeWindow;
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (id.isNotEmpty) StoryColumns.id: id,
      StoryColumns.imageUrl: imageUrl,
      StoryColumns.videoUrl: videoUrl,
      StoryColumns.contentText: contentText,
      StoryColumns.backgroundColor: backgroundColor,
      StoryColumns.authorId: authorId,
      StoryColumns.createdAt:
          DateTime.parse(createdAt).toUtc().toIso8601String(),
      StoryColumns.storyCaption: caption,

      StoryColumns.imagePublicId: imagePublicId,
      StoryColumns.videoPublicId: videoPublicId,
      StoryColumns.videoDurationSeconds: videoDurationSeconds,
    };
  }

  factory StoryModel.fromMap(Map<String, dynamic> map) {
    final userData = map[SupabaseConstants.users] as Map<String, dynamic>?;
    String formattedLocalTime = '';
    if (map[StoryColumns.createdAt] != null) {
      formattedLocalTime =
          DateTime.parse(
            map[StoryColumns.createdAt].toString(),
          ).toLocal().toString();
    }

    return StoryModel(
      id: map[StoryColumns.id] as String,
      imageUrl: map[StoryColumns.imageUrl] as String?,
      videoUrl: map[StoryColumns.videoUrl] as String?,
      contentText: map[StoryColumns.contentText] as String?,
      backgroundColor: map[StoryColumns.backgroundColor] as String?,
      authorId: map[StoryColumns.authorId] as String? ?? '',
      authorName: userData?[UserColumns.name] as String? ?? 'Unknown User',
      authorImageUrl: userData?[UserColumns.imageUrl] as String?,
      createdAt: formattedLocalTime,
      caption: map[StoryColumns.storyCaption] as String?,
      lastSeen:
          userData != null && userData[UserColumns.lastSeen] != null
              ? DateTime.parse(userData[UserColumns.lastSeen].toString())
              : null,
      videoDurationSeconds:
          (map[StoryColumns.videoDurationSeconds] as num?)?.toInt(),
    );
  }

  ChatUserModel toChatUserModel() {
    return ChatUserModel(
      id: authorId,
      name: authorName,
      imageUrl: authorImageUrl,
      lastSeen: lastSeen,
    );
  }

  Map<String, dynamic> toCacheJson() => {
    'id': id,
    'image_url': imageUrl,
    'video_url': videoUrl,
    'content_text': contentText,
    'background_color': backgroundColor,
    'author_id': authorId,
    'author_name': authorName,
    'author_image_url': authorImageUrl,
    'created_at': createdAt,
    'caption': caption,
    'last_seen': lastSeen?.toIso8601String(),
    'image_public_id': imagePublicId,
    'video_public_id': videoPublicId,
    'video_duration_seconds': videoDurationSeconds,
  };

  factory StoryModel.fromCacheJson(Map<String, dynamic> map) {
    return StoryModel(
      id: map['id'] as String? ?? '',
      imageUrl: map['image_url'] as String?,
      videoUrl: map['video_url'] as String?,
      contentText: map['content_text'] as String?,
      backgroundColor: map['background_color'] as String?,
      authorId: map['author_id'] as String? ?? '',
      authorName: map['author_name'] as String? ?? 'Unknown User',
      authorImageUrl: map['author_image_url'] as String?,
      createdAt: map['created_at'] as String? ?? '',
      caption: map['caption'] as String?,
      lastSeen:
          map['last_seen'] != null
              ? DateTime.parse(map['last_seen'] as String)
              : null,
      imagePublicId: map['image_public_id'] as String?,
      videoPublicId: map['video_public_id'] as String?,
      videoDurationSeconds: (map['video_duration_seconds'] as num?)?.toInt(),
    );
  }
}
