enum CommentType { text, image, video, voice, file, gif, sticker }

extension CommentTypeX on CommentType {
  String get value => name;

  bool get requiresUpload =>
      this == CommentType.image ||
      this == CommentType.video ||
      this == CommentType.voice ||
      this == CommentType.file;
}

CommentType commentTypeFromString(String? value) {
  return CommentType.values.firstWhere(
    (t) => t.name == value,
    orElse: () => CommentType.text,
  );
}
