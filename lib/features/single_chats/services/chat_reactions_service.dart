import '../../../core/supabase/supabase_provider.dart';
import '../../../core/utilities/supabase_constants.dart';

class ChatReactionsService {
  final _supabase = SupabaseProvider.client;

  Future<void> toggleReaction({
    required String messageId,
    required String conversationId,
    required String emoji,
  }) async {
    await _supabase.rpc(
      'toggle_message_reaction',
      params: {
        'p_message_id': messageId,
        'p_conversation_id': conversationId,
        'p_emoji': emoji,
      },
    );
  }

  Stream<List<Map<String, dynamic>>> getMessageReactionsStream(
    String conversationId,
  ) {
    return _supabase
        .from(SupabaseConstants.messageReactions)
        .stream(primaryKey: [MessageReactionColumns.id])
        .eq(MessageReactionColumns.conversationId, conversationId);
  }
}
