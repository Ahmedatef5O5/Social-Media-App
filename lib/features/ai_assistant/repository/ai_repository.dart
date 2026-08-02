import '../entities/ai_action_type.dart';
import '../entities/ai_request_context.dart';
import '../entities/ai_result.dart';

abstract class AiRepository {
  Future<AiResult> generateCaption(AiRequestContext context);

  Future<AiResult> checkSpelling(AiRequestContext context);

  Future<AiResult> suggestReply(AiRequestContext context);

  Future<AiResult> getCommentSuggestions({
    required String postId,
    required String postText,
  });

  Future<AiResult> summarizeChat({
    required String transcript,
    required AiActionType mode,
  });
}
