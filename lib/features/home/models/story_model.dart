class StoryModel {
  final String id;
  final String imageUrl;
  final String authorId;
  final String createdAt;

  const StoryModel({
    required this.id,
    required this.imageUrl,
    required this.authorId,
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
    return StoryModel(
      id: map['id'] as String,
      imageUrl: map['image_url'] as String? ?? '',
      authorId: map['author_id'] as String? ?? '',
      createdAt: map['created_at'] as String? ?? '',
    );
  }

  // String toJson() => json.encode(toMap());
  // factory StoryModel.fromJson(String source) => StoryModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
