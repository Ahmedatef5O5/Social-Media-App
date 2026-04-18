import 'package:social_media_app/core/utilities/supabase_constants.dart';
import 'package:social_media_app/features/chats/models/chat_user_model.dart';
import '../../comments/model/comment_model.dart';

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
  final DateTime? lastSeen;

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
    this.lastSeen,
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
    );
  }

  factory PostModel.fromMap(Map<String, dynamic> map) {
    final userData = map[SupabaseConstants.users] as Map<String, dynamic>?;
    final commentsData = map[SupabaseConstants.comments] as List<dynamic>?;
    List<String> likesList = [];
    List<String> imagesList = [];
    if (map[SupabaseConstants.likes] != null) {
      final likesData = map[SupabaseConstants.likes] as List<dynamic>;
      for (var item in likesData) {
        likesList.add(item['user_id'].toString());
        if (item['users'] != null && item['users']['image_url'] != null) {
          imagesList.add(item['users']['image_url'].toString());
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
      authorImageUrl:
          userData != null ? userData[UserColumns.imageUrl] as String? : null,
      videoUrl:
          map['video_url'] != null ? map['video_url'] as String? ?? '' : null,
      imageUrl: map['image_url'] != null ? map['image_url'] as String : null,
      fileUrl: map['file_url'] != null ? map['file_url'] as String : null,

      likes: likesList,
      likersImages: imagesList,
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
    final DateTime? lastSeen,
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
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}
