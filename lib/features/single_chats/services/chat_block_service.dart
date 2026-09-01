import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/helpers/chat_helper.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/utilities/supabase_constants.dart';
import '../models/chat_block_status.dart';
import '../models/message_model.dart';

class ChatBlockService {
  final _supabase = SupabaseProvider.client;

  Future<ChatBlockStatus> getBlockStatus({
    required String currentUserId,
    required String otherUserId,
  }) async {
    final rows = await _supabase
        .from(SupabaseConstants.blockedUsers)
        .select(
          '${BlockedUsersColumns.blockerId}, ${BlockedUsersColumns.blockedId}',
        )
        .or(
          'and(${BlockedUsersColumns.blockerId}.eq.$currentUserId,${BlockedUsersColumns.blockedId}.eq.$otherUserId),'
          'and(${BlockedUsersColumns.blockerId}.eq.$otherUserId,${BlockedUsersColumns.blockedId}.eq.$currentUserId)',
        );

    bool blockedByMe = false;
    bool blockedByThem = false;
    for (final row in rows as List) {
      final blockerId = row[BlockedUsersColumns.blockerId] as String?;
      if (blockerId == currentUserId) blockedByMe = true;
      if (blockerId == otherUserId) blockedByThem = true;
    }
    final status = ChatBlockStatus(
      blockedByMe: blockedByMe,
      blockedByThem: blockedByThem,
      isLoaded: true,
    );

    unawaited(ChatBlockStatusCache.instance.write(otherUserId, status));

    return status;
  }

  Stream<ChatBlockStatus> watchBlockStatus({
    required String currentUserId,
    required String otherUserId,
  }) {
    final controller = StreamController<ChatBlockStatus>.broadcast();

    Future<void> refresh() async {
      try {
        final status = await getBlockStatus(
          currentUserId: currentUserId,
          otherUserId: otherUserId,
        );
        if (!controller.isClosed) controller.add(status);
    } catch (e) {
  debugPrint('[ChatBlockService] failed to fetch block status: $e');
}}

    final channelName =
        'blocked_users_${ChatHelper.buildConversationId(currentUserId, otherUserId)}';
    _supabase.removeChannel(_supabase.channel(channelName));
    final channel = _supabase.channel(channelName);

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseConstants.blockedUsers,
          callback: (_) => refresh(),
        )
        .subscribe();

    refresh();

    controller.onCancel = () {
      _supabase.removeChannel(channel);
      controller.close();
    };

    return controller.stream;
  }

  static const _personFields = 'id,name,image_url,title,last_seen';

  Future<List<Map<String, dynamic>>> getBlockedUsersList() async {
    final rows = await _supabase
        .from(SupabaseConstants.blockedUsers)
        .select(
          '${BlockedUsersColumns.blockedId}, ${BlockedUsersColumns.createdAt}, '
          'blocked_user:${BlockedUsersColumns.blockedId}($_personFields)',
        )
        .eq(BlockedUsersColumns.blockerId, SupabaseProvider.id)
        .order(BlockedUsersColumns.createdAt, ascending: false);

    return List<Map<String, dynamic>>.from(rows as List);
  }


  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    await _supabase
        .from(SupabaseConstants.blockedUsers)
        .delete()
        .eq(BlockedUsersColumns.blockerId, blockerId)
        .eq(BlockedUsersColumns.blockedId, blockedId);

    await _supabase.from(SupabaseConstants.blockedUsers).insert({
      BlockedUsersColumns.blockerId: blockerId,
      BlockedUsersColumns.blockedId: blockedId,
    });

    await _supabase.from(SupabaseConstants.messages).insert({
      MessagesColumns.senderId: blockerId,
      MessagesColumns.receiverId: blockedId,
      MessagesColumns.messageText: 'blocked',
      MessagesColumns.messageType: MessageModel.blockEventType,
    });
  }

  Future<void> unblockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    await _supabase
        .from(SupabaseConstants.blockedUsers)
        .delete()
        .eq(BlockedUsersColumns.blockerId, blockerId)
        .eq(BlockedUsersColumns.blockedId, blockedId);

    await _supabase.from(SupabaseConstants.messages).insert({
      MessagesColumns.senderId: blockerId,
      MessagesColumns.receiverId: blockedId,
      MessagesColumns.messageText: 'unblocked',
      MessagesColumns.messageType: MessageModel.unblockEventType,
    });
  }
}
