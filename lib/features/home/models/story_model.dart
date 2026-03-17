import 'package:social_media_app/core/utilities/app_tables_names.dart';

class StoryModel {
  final String id;
  final String? imageUrl;
  final String? contentText;
  final String? backgroundColor;
  final String authorId;
  final String authorName;
  final String? authorImageUrl;
  final String createdAt;

  const StoryModel({
    this.id = '',
    this.imageUrl,
    this.contentText,
    this.backgroundColor,
    required this.authorId,
    required this.authorName,
    this.authorImageUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (id.isNotEmpty) 'id': id,
      'image_url': imageUrl,
      'content_text': contentText,
      'background_color': backgroundColor,
      'author_id': authorId,
      'created_at': createdAt,
    };
  }

  factory StoryModel.fromMap(Map<String, dynamic> map) {
    final userData = map[AppTablesNames.users] as Map<String, dynamic>?;
    return StoryModel(
      id: map[StoryColumns.id] as String,
      imageUrl: map[StoryColumns.imageUrl] as String?,
      contentText: map[StoryColumns.contentText] as String?,
      backgroundColor: map[StoryColumns.backgroundColor] as String?,
      authorId: map[StoryColumns.authorId] as String? ?? '',
      authorName: userData?[UserColumns.name] as String? ?? 'Unknown User',
      authorImageUrl: userData?[UserColumns.imageUrl] as String?,
      createdAt: map[StoryColumns.createdAt] as String? ?? '',
    );
  }
}
