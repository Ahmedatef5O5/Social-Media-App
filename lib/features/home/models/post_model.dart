import 'package:social_media_app/core/utilities/app_tables_names.dart';

class PostModel {
  final String id;
  final String text;
  final String authorId;
  final String createdAt;
  final String? authorName;
  final String? authorImageUrl;
  final String? videoUrl;
  final String? imageUrl;
  final List<String>? likes;
  final List<String>? comments;
  final List<String>? shares;

  const PostModel({
    required this.id,
    required this.text,
    required this.authorId,
    required this.createdAt,
    this.authorName,
    this.authorImageUrl,
    this.videoUrl,
    this.imageUrl,
    this.likes,
    this.comments,
    this.shares,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'text': text,
      'authorId': authorId,
      'createdAt': createdAt,
      'authorName': authorName,
      'authorImageUrl': authorImageUrl,
      'videoUrl': videoUrl,
      'imageUrl': imageUrl,
      'likes': likes,
      'comments': comments,
      'shares': shares,
    };
  }

  factory PostModel.fromMap(Map<String, dynamic> map) {
    final userData = map[AppTablesNames.users] as Map<String, dynamic>?;
    return PostModel(
      id: map['id'] as String? ?? '',
      text: map[PostColumns.text] as String? ?? '',
      authorId: map[PostColumns.authorId] as String? ?? '',
      createdAt: map[PostColumns.createdAt] as String? ?? '',
      authorName:
          userData != null
              ? userData[UserColumns.name] as String? ?? 'Unknown User'
              : null,
      // authorImageUrl:
      //     map['authorImageUrl'] != null
      //         ? map['authorImageUrl'] as String? ?? ''
      //         : null,
      videoUrl:
          map['videoUrl'] != null ? map['videoUrl'] as String? ?? '' : null,
      imageUrl: map['image_url'] != null ? map['image_url'] as String : null,
      likes:
          map[PostColumns.likes] != null
              ? List<String>.from(map[PostColumns.likes])
              : [],
      comments:
          map[PostColumns.comments] != null
              ? List<String>.from(map[PostColumns.comments])
              : [],
      shares:
          map[PostColumns.shares] != null
              ? List<String>.from(map[PostColumns.shares])
              : [],
    );
  }

  // String toJson() => json.encode(toMap());

  // factory PostModel.fromJson(String source) => PostModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
