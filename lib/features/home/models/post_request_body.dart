// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:io';

class PostRequestBody {
  final String text;
  final String authorId;
  final File? image;
  final File? file;

  const PostRequestBody({
    required this.text,
    required this.authorId,
    this.image,
    this.file,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'text': text,
      'author_id': authorId,
      // 'image': image?.toMap(),
      // 'file': file?.toMap(),
    };
  }

  factory PostRequestBody.fromMap(Map<String, dynamic> map) {
    return PostRequestBody(
      text: map['text'] as String,
      authorId: map['author_id'] as String,
      // image:
      //     map['image'] != null
      //         ? File.fromMap(map['image'] as Map<String, dynamic>)
      //         : null,
      // file:
      //     map['file'] != null
      //         ? File.fromMap(map['file'] as Map<String, dynamic>)
      //         : null,
    );
  }

  // String toJson() => json.encode(toMap());

  // factory PostRequestBody.fromJson(String source) => PostRequestBody.fromMap(json.decode(source) as Map<String, dynamic>);
}
