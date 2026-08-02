enum AiSurfaceType { chatMessage, comment, story, post }

class AiRequestContext {
  final AiSurfaceType surface;
  final String? currentText;
  final String? replyToText;
  final String? replyToAuthorName;
  final String? parentContentText;
  final bool hasMediaAttached;
  final String? chatTranscript;

  final String? imageBase64;

  const AiRequestContext({
    required this.surface,
    this.currentText,
    this.replyToText,
    this.replyToAuthorName,
    this.parentContentText,
    this.hasMediaAttached = false,
    this.chatTranscript,
    this.imageBase64,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'surface': surface.name,
      if (currentText != null) 'current_text': currentText,
      if (replyToText != null) 'reply_to_text': replyToText,
      if (replyToAuthorName != null) 'reply_to_author_name': replyToAuthorName,
      if (parentContentText != null) 'parent_content_text': parentContentText,
      'has_media_attached': hasMediaAttached,
      if (chatTranscript != null) 'chat_transcript': chatTranscript,
      if (imageBase64 != null) 'image_base64': imageBase64,
      if (imageBase64 != null) 'image_mime_type': 'image/jpeg',
    };
  }
}