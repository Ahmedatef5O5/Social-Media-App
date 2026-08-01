import '../../social_graph/models/content_privacy.dart';

class PostRequestBody {
  final String? id;
  final String text;
  final String authorId;
  final String? imageUrl;
  final String? videoUrl;
  final String? fileUrl;
  final String? imagePublicId;
  final String? videoPublicId;
  final String? filePublicId;
  final int? mediaWidth;
  final int? mediaHeight;
  final ContentPrivacy privacyType;

  const PostRequestBody({
    this.id,
    required this.text,
    required this.authorId,
    this.imageUrl,
    this.videoUrl,
    this.fileUrl,
    this.imagePublicId,
    this.videoPublicId,
    this.filePublicId,
    this.mediaWidth,
    this.mediaHeight,
    this.privacyType = ContentPrivacy.public,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      'text': text,
      'author_id': authorId,
      'image_url': imageUrl,
      'video_url': videoUrl,
      'file_url': fileUrl,
      'image_public_id': imagePublicId,
      'video_public_id': videoPublicId,
      'file_public_id': filePublicId,
      'media_width': mediaWidth,
      'media_height': mediaHeight,
      'privacy_type': contentPrivacyToString(privacyType),
    };
  }

  factory PostRequestBody.fromMap(Map<String, dynamic> map) {
    return PostRequestBody(
      text: map['text'] as String,
      authorId: map['author_id'] as String,
      imageUrl: map['image_url'] as String?,
      videoUrl: map['video_url'] as String?,
      fileUrl: map['file_url'] as String?,
      mediaWidth: map['media_width'] as int?,
      mediaHeight: map['media_height'] as int?,
    );
  }
}
