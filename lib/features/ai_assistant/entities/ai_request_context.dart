import 'ai_autocomplete_language.dart';
import 'ai_reply_length.dart';
import 'ai_reply_tone.dart';

enum AiSurfaceType { chatMessage, groupChatMessage, comment, story, post }

enum AiActionContext {
  chatReply,
  storyReply,
  commentReply,
  postCreation,
  storyCreation,
  mediaCaption,
  spellCheck;

  String get wireValue {
    switch (this) {
      case AiActionContext.chatReply:
        return 'chat_reply';
      case AiActionContext.storyReply:
        return 'story_reply';
      case AiActionContext.commentReply:
        return 'comment_reply';
      case AiActionContext.postCreation:
        return 'post_creation';
      case AiActionContext.storyCreation:
        return 'story_creation';
      case AiActionContext.mediaCaption:
        return 'media_caption';
      case AiActionContext.spellCheck:
        return 'spell_check';
    }
  }
}

enum AiTargetMediaType {
  text,
  image,
  video,
  voiceRecord,
  document,
  gif,
  sticker,
  none;

  String get wireValue {
    switch (this) {
      case AiTargetMediaType.text:
        return 'text';
      case AiTargetMediaType.image:
        return 'image';
      case AiTargetMediaType.video:
        return 'video';
      case AiTargetMediaType.voiceRecord:
        return 'voice_record';
      case AiTargetMediaType.document:
        return 'document';
      case AiTargetMediaType.gif:
        return 'gif';
      case AiTargetMediaType.sticker:
        return 'sticker';
      case AiTargetMediaType.none:
        return 'none';
    }
  }

  static AiTargetMediaType fromWireMessageType(String? type) {
    switch (type) {
      case 'image':
        return AiTargetMediaType.image;
      case 'video':
        return AiTargetMediaType.video;
      case 'voice':
        return AiTargetMediaType.voiceRecord;
      case 'file':
        return AiTargetMediaType.document;
      case 'gif':
        return AiTargetMediaType.gif;
      case 'sticker':
        return AiTargetMediaType.sticker;
      case 'text':
        return AiTargetMediaType.text;
      default:
        return AiTargetMediaType.none;
    }
  }
}

class AiRequestContext {
  final AiSurfaceType surface;
  final AiActionContext actionContext;
  final String? userDraft; // current text
  final String? targetUserName; // replyToAuthorName
  final AiTargetMediaType targetMediaType;
  final String? targetText;
  final String? mediaCaption;
  final bool hasMediaAttached;
  final String? chatTranscript;
  final String? imageBase64;
  final AiAutoCompleteLanguage userLanguage;
  final AiReplyTone userTone;
  final AiReplyLength userLength;

  const AiRequestContext({
    required this.surface,
    required this.actionContext,
    this.userDraft,
    this.targetUserName,
    this.targetMediaType = AiTargetMediaType.none,
    this.targetText,
    this.mediaCaption,
    this.hasMediaAttached = false,
    this.chatTranscript,
    this.imageBase64,
    this.userLanguage = AiAutoCompleteLanguage.auto,
    this.userTone = AiReplyTone.standard,
    this.userLength = AiReplyLength.standard,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'surface': surface.name,
      'action_type': actionContext.wireValue,
      if (userDraft != null) 'user_draft': userDraft,
      if (targetUserName != null) 'target_user_name': targetUserName,
      'target_media_type': targetMediaType.wireValue,
      if (targetText != null) 'target_text': targetText,
      if (mediaCaption != null) 'media_caption': mediaCaption,
      'has_media_attached': hasMediaAttached,
      if (chatTranscript != null) 'chat_transcript': chatTranscript,
      if (imageBase64 != null) 'image_base64': imageBase64,
      if (imageBase64 != null) 'image_mime_type': 'image/jpeg',
      'user_language': userLanguage.wireValue,
      'user_tone': userTone.wireValue,
      'user_length': userLength.wireValue,
    };
  }
}
