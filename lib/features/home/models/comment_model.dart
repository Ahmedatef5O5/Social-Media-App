import 'package:social_media_app/core/utilities/app_tables_names.dart';

class CommentModel {
  final String id;
  final String createdAt;
  final String authorId;
  final String text;
  final String? authorName;
  final String? authorImageUrl;
  final String postId;
  final String? imageUrl;
  final List<String>? replays;
  final List<String>? likes;

  const CommentModel({
    required this.id,
    required this.createdAt,
    required this.authorId,
    required this.text,
    this.authorName,
    this.authorImageUrl,
    required this.postId,
    this.imageUrl,
    this.replays,
    this.likes,
  });

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
      'replays': replays,
      'likes': likes,
    };
  }

  factory CommentModel.fromMap(Map<String, dynamic> map) {
    final userData = map[AppTablesNames.users] as Map<String, dynamic>?;

    return CommentModel(
      id: map['id'] as String,
      createdAt: map['created_at'] as String,
      authorId: map['author_id'] as String,
      text: map['text'] as String,
      authorName:
          userData != null ? userData[UserColumns.name] as String? : null,
      // map['authorName'] != null ? map['authorName'] as String : null,
      authorImageUrl:
          userData != null ? userData[UserColumns.imageUrl] as String? : null,
      postId: map['post_id'] as String,
      imageUrl: map['image_url'] != null ? map['image_url'] as String : null,

      // replays:
      // likes:
    );
  }

  // String toJson() => json.encode(toMap());

  // factory CommentModel.fromJson(String source) =>
  //     CommentModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
