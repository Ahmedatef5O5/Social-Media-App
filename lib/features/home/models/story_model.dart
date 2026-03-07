import 'package:social_media_app/core/utilities/app_tables_names.dart';

class StoryModel {
  final String id;
  final String imageUrl;
  final String authorId;
  final String authorName;
  final String? authorImageUrl;
  final String createdAt;

  const StoryModel({
    required this.id,
    required this.imageUrl,
    required this.authorId,
    required this.authorName,
    this.authorImageUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'image_url': imageUrl,
      'author_id': authorId,
      'created_at': createdAt,
    };
  }

  factory StoryModel.fromMap(Map<String, dynamic> map) {
    final userData = map[AppTablesNames.users] as Map<String, dynamic>?;
    return StoryModel(
      id: map[StoryColumns.id] as String,
      imageUrl: map[StoryColumns.imageUrl] as String? ?? '',
      authorId: map[StoryColumns.authorId] as String? ?? '',
      authorName: userData?[UserColumns.name] as String? ?? 'Unknown User',
      authorImageUrl: userData?['image_url'] as String?,
      createdAt: map[StoryColumns.createdAt] as String? ?? '',
    );
  }

  // String toJson() => json.encode(toMap());
  // factory StoryModel.fromJson(String source) => StoryModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
