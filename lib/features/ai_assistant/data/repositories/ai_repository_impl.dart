import '../../entities/ai_action_type.dart';
import '../../entities/ai_request_context.dart';
import '../../entities/ai_result.dart';
import '../../repository/ai_repository.dart';
import '../../services/ai_remote_service.dart';

class AiRepositoryImpl implements AiRepository {
  final AiRemoteService _remote;

  AiRepositoryImpl({AiRemoteService? remoteService})
    : _remote = remoteService ?? AiRemoteService();

  @override
  Future<AiResult> generateCaption(AiRequestContext context) async {
    final json = await _remote.invoke(
      action: AiActionType.autocompleteCaption.wireValue,
      payload: context.toJson(),
    );
    return AiResult.fromJson(json);
  }

  @override
  Future<AiResult> checkSpelling(AiRequestContext context) async {
    final json = await _remote.invoke(
      action: AiActionType.spellCheck.wireValue,
      payload: context.toJson(),
    );
    return AiResult.fromJson(json);
  }

  @override
  Future<AiResult> suggestReply(AiRequestContext context) async {
    final json = await _remote.invoke(
      action: AiActionType.replySuggestion.wireValue,
      payload: context.toJson(),
    );
    return AiResult.fromJson(json);
  }

  @override
  Future<AiResult> getCommentSuggestions({
    required String postId,
    required String postText,
    String? imageBase64,
    String? imageMimeType,
  }) async {
    final json = await _remote.invoke(
      action: AiActionType.commentSuggestions.wireValue,
      payload: {
        'post_id': postId,
        'post_text': postText,
        if (imageBase64 != null) 'image_base64': imageBase64,
        if (imageMimeType != null) 'image_mime_type': imageMimeType,
      },
    );
    return AiResult.fromJson(json);
  }

  @override
  Future<AiResult> summarizeChat({
    required String transcript,
    required AiActionType mode,
  }) async {
    final json = await _remote.invoke(
      action: mode.wireValue,
      payload: {'chat_transcript': transcript},
    );
    return AiResult.fromJson(json);
  }
}
