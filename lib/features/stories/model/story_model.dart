import 'package:social_media_app/core/utilities/supabase_constants.dart';
import 'package:social_media_app/features/chats/models/chat_user_model.dart';

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
  });

  StoryType get storyType {
    if (videoUrl != null) return StoryType.video;
    if (imageUrl != null) return StoryType.image;
    return StoryType.text;
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
}
