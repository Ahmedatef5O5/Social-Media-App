class PostRequestBody {
  final String text;
  final String authorId;
  final String? imageUrl;
  final String? fileUrl;

  const PostRequestBody({
    required this.text,
    required this.authorId,
    this.imageUrl,
    this.fileUrl,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'text': text,
      'author_id': authorId,
      'image_url': imageUrl,
      'file_url': fileUrl,
    };
  }

  factory PostRequestBody.fromMap(Map<String, dynamic> map) {
    return PostRequestBody(
      text: map['text'] as String,
      authorId: map['author_id'] as String,
      imageUrl: map['image_url'] as String?,
      fileUrl: map['file_url'] as String?,
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
