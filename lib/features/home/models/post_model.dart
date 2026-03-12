import 'package:social_media_app/core/utilities/app_tables_names.dart';

import 'comment_model.dart';

class PostModel {
  bool isLikedBy(String userId) => likes?.contains(userId) ?? false;
  int get likesCount => likes?.length ?? 0;

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
  final List<CommentModel>? comments;
  final List<String>? shares;

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
      'fileUrl': fileUrl,
      'imageUrl': imageUrl,
      'likes': likes,
      'likers_images': likersImages,
      'comments': comments,
      'shares': shares,
    };
  }

  factory PostModel.fromMap(Map<String, dynamic> map) {
    final userData = map[AppTablesNames.users] as Map<String, dynamic>?;
    final commentsData = map[AppTablesNames.comments] as List<dynamic>?;
    // final likedUsersData = map['liked_users'] as List<dynamic>?;
    List<String> images = [];
    if (map['liked_users'] != null) {
      if (map['liked_users'] is List) {
        images =
            (map['liked_users'] as List)
                .map((user) => user[UserColumns.imageUrl]?.toString() ?? '')
                .where((url) => url.isNotEmpty)
                .toList();
      } else if (map['liked_users'] is Map) {
        final imageUrl = map['liked_users'][UserColumns.imageUrl]?.toString();
        if (imageUrl != null) {
          images = [imageUrl];
        }
      }
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
      videoUrl:
          map['video_url'] != null ? map['video_url'] as String? ?? '' : null,
      imageUrl: map['image_url'] != null ? map['image_url'] as String : null,
      fileUrl: map['file_url'] != null ? map['file_url'] as String : null,
      likes:
          map[PostColumns.likes] != null
              ? List<String>.from(map[PostColumns.likes])
              : [],
      likersImages: images,
      comments:
          commentsData != null
              ? commentsData.map((c) => CommentModel.fromMap(c)).toList()
              : [],
      shares:
          map[PostColumns.shares] != null
              ? List<String>.from(map[PostColumns.shares])
              : [],
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
    List<CommentModel>? comments,
    List<String>? shares,
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
      likersImages: likes ?? this.likersImages,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
    );
  }
}
