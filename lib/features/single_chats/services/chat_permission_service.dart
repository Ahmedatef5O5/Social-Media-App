import 'package:social_media_app/core/helpers/chat_helper.dart';
import 'package:social_media_app/core/supabase/supabase_provider.dart';
import 'package:social_media_app/core/utilities/supabase_constants.dart';

enum ChatPermission { allowed, needsRequest, awaitingMyResponse }

class ChatPermissionResult {
  final ChatPermission permission;
  final String? messageRequestId;
  const ChatPermissionResult({required this.permission, this.messageRequestId});
}

class ChatPermissionService {
  final _supabase = SupabaseProvider.client;

  Future<ChatPermissionResult> resolve({
    required String currentUserId,
    required String otherUserId,
  }) async {
    // 1) صداقة/متابعة بالفعل؟
    final connected =
        await _supabase.rpc(
              'are_users_connected',
              params: {'user_a': currentUserId, 'user_b': otherUserId},
            )
            as bool;
    if (connected) {
      return const ChatPermissionResult(permission: ChatPermission.allowed);
    }

    // 2) Grandfather Clause: فيه محادثة قديمة أصلاً؟
    final conversationId = ChatHelper.buildConversationId(
      currentUserId,
      otherUserId,
    );
    final existingMessages = await _supabase
        .from(SupabaseConstants.messages)
        .select(MessagesColumns.id)
        .eq(MessagesColumns.conversationId, conversationId)
        .limit(1);
    if ((existingMessages as List).isNotEmpty) {
      return const ChatPermissionResult(permission: ChatPermission.allowed);
    }

    // 3) هل فيه Message Request قايم أصلاً؟
    final rows = await _supabase
        .from(SupabaseConstants.messageRequests)
        .select()
        .or(
          'and(sender_id.eq.$currentUserId,receiver_id.eq.$otherUserId),'
          'and(sender_id.eq.$otherUserId,receiver_id.eq.$currentUserId)',
        )
        .limit(1);

    if ((rows as List).isEmpty) {
      return const ChatPermissionResult(
        permission: ChatPermission.needsRequest,
      );
    }

    // ignore: unnecessary_cast
    final row = rows.first as Map<String, dynamic>;
    final status = row['status'] as String;
    final requestId = row['id'] as String;
    final senderId = row['sender_id'] as String;

    if (status == 'accepted' || senderId == currentUserId) {
      return ChatPermissionResult(
        permission: ChatPermission.allowed,
        messageRequestId: requestId,
      );
    }
    return ChatPermissionResult(
      permission: ChatPermission.awaitingMyResponse,
      messageRequestId: requestId,
    );
  }

  Future<String> createRequest({
    required String senderId,
    required String receiverId,
  }) async {
    final row =
        await _supabase
            .from(SupabaseConstants.messageRequests)
            .insert({'sender_id': senderId, 'receiver_id': receiverId})
            .select('id')
            .single();
    return row['id'] as String;
  }

  Future<void> acceptRequest(String requestId) async {
    await _supabase
        .from(SupabaseConstants.messageRequests)
        .update({
          'status': 'accepted',
          'responded_at': DateTime.now().toIso8601String(),
        })
        .eq('id', requestId);
  }

  Future<void> declineRequest(String requestId) async {
    await _supabase
        .from(SupabaseConstants.messageRequests)
        .update({
          'status': 'declined',
          'responded_at': DateTime.now().toIso8601String(),
        })
        .eq('id', requestId);
  }
}
