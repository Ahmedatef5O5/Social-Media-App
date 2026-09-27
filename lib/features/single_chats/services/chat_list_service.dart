import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/chat_shared/helpers/message_reaction_preview_helper.dart';
import '../../../core/helpers/chat_helper.dart';
import '../../../core/services/network_status_service.dart';
import '../../../core/presence/services/presence_service.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/utilities/supabase_constants.dart';
import '../models/chat_user_model.dart';

class ChatListService {
  final _supabase = SupabaseProvider.client;
  final NetworkStatusService _networkStatus;

  ChatListService({NetworkStatusService? networkStatus})
    : _networkStatus = networkStatus ?? NetworkStatusService.instance;

  Future<ReceiverPushInfo?> getReceiverPushInfo(String receiverId) async {
    try {
      final data =
          await _supabase
              .from(SupabaseConstants.users)
              .select(
                '${UserColumns.id}, '
                '${UserColumns.name}, '
                '${UserColumns.imageUrl}, '
                '${UserColumns.fcmToken}',
              )
              .eq(UserColumns.id, receiverId)
              .maybeSingle();

      if (data == null) return null;
      final token = data[UserColumns.fcmToken] as String?;
      if (token == null || token.isEmpty) return null;

      return ReceiverPushInfo(
        fcmToken: token,
        name: (data[UserColumns.name] as String?) ?? 'Unknown',
        imageUrl: (data[UserColumns.imageUrl] as String?) ?? '',
      );
    } catch (e) {
      debugPrint('⚠️  getReceiverPushInfo failed: $e');
      return null;
    }
  }

  Future<void> saveMyFcmToken(String userId, String token) async {
    try {
      await _supabase
          .from(SupabaseConstants.users)
          .update({UserColumns.fcmToken: token})
          .eq(UserColumns.id, userId);
      debugPrint('✅ FCM token saved to Supabase');
    } catch (e) {
      debugPrint('⚠️  saveMyFcmToken failed: $e');
    }
  }

  Future<List<ChatUserModel>> getChatsList(String currentUserId) async {
    if (!(await _networkStatus.isConnected())) {
      throw Exception('no-internet');
    }

    try {
      final response = await _supabase.rpc(
        SupabaseConstants.getChatsWithLastMessage,
        params: {'current_user_id': currentUserId},
      );

      if (response == null) return [];

      final chats =
          (response as List)
              .map((data) => ChatUserModel.fromUserData(data, currentUserId))
              .toList();

      if (chats.isEmpty) return chats;

      final userIds = chats.map((c) => c.id).toList();
      final presenceRows = await _supabase
          .from(SupabaseConstants.userPresence)
          .select('user_id, is_online, updated_at')
          .inFilter('user_id', userIds);

      final onlineSet = <String>{
        for (final row in presenceRows as List)
          if (PresenceService.isConsideredOnline(
            isOnline: row[PresenceColumns.isOnline] as bool? ?? false,
            updatedAt:
                row[PresenceColumns.updatedAt] != null
                    ? DateTime.parse(row[PresenceColumns.updatedAt].toString())
                    : null,
          ))
            row['user_id'] as String,
      };

      var enrichedChats =
          chats
              .map((c) => c.copyWith(isOnline: onlineSet.contains(c.id)))
              .toList();

      enrichedChats = await _enrichWithLatestReactions(
        enrichedChats,
        currentUserId,
      );

      return enrichedChats;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ChatUserModel>> _enrichWithLatestReactions(
    List<ChatUserModel> chats,
    String currentUserId,
  ) async {
    try {
      final convIdByPeerId = <String, String>{
        for (final chat in chats)
          chat.id: ChatHelper.buildConversationId(currentUserId, chat.id),
      };

      final conversationIds = convIdByPeerId.values.toList();
      if (conversationIds.isEmpty) return chats;

      final reactionRows = await _supabase
          .from(SupabaseConstants.messageReactions)
          .select('message_id, user_id, reaction, conversation_id, created_at')
          .inFilter(MessageReactionColumns.conversationId, conversationIds)
          .order(MessageReactionColumns.createdAt, ascending: false);

      final latestReactionByConv = <String, Map<String, dynamic>>{};
      for (final r in (reactionRows as List)) {
        final row = r as Map<String, dynamic>;
        final convId = row[MessageReactionColumns.conversationId] as String?;
        if (convId != null && !latestReactionByConv.containsKey(convId)) {
          latestReactionByConv[convId] = row;
        }
      }

      if (latestReactionByConv.isEmpty) return chats;

      final targetMessageIds = <String>{};
      for (final chat in chats) {
        final convId = convIdByPeerId[chat.id];
        final reactionRow =
            convId != null ? latestReactionByConv[convId] : null;
        if (reactionRow == null) continue;

        final createdAtStr =
            reactionRow[MessageReactionColumns.createdAt] as String?;
        final reactionTime =
            createdAtStr != null ? DateTime.tryParse(createdAtStr) : null;
        if (reactionTime == null) continue;

        if (chat.lastMessageTime == null ||
            reactionTime.isAfter(chat.lastMessageTime!)) {
          final msgId =
              reactionRow[MessageReactionColumns.messageId] as String?;
          if (msgId != null && msgId.isNotEmpty) {
            targetMessageIds.add(msgId);
          }
        }
      }

      if (targetMessageIds.isEmpty) return chats;

      final msgRows = await _supabase
          .from(SupabaseConstants.messages)
          .select(
            'id, message_text, message_type, caption, file_name, deleted_for',
          )
          .inFilter(MessagesColumns.id, targetMessageIds.toList());

      final messagesById = <String, Map<String, dynamic>>{};
      for (final m in (msgRows as List)) {
        final map = m as Map<String, dynamic>;
        final deletedFor =
            (map[MessagesColumns.deletedFor] as List?)?.cast<String>() ?? [];
        if (deletedFor.contains(currentUserId)) continue;
        final id = map[MessagesColumns.id] as String?;
        if (id != null) {
          messagesById[id] = map;
        }
      }

      if (messagesById.isEmpty) return chats;

      final updated =
          chats.map((chat) {
            final convId = convIdByPeerId[chat.id];
            final reactionRow =
                convId != null ? latestReactionByConv[convId] : null;
            if (reactionRow == null) return chat;

            final createdAtStr =
                reactionRow[MessageReactionColumns.createdAt] as String?;
            final reactionTime =
                createdAtStr != null ? DateTime.tryParse(createdAtStr) : null;
            if (reactionTime == null) return chat;

            if (chat.lastMessageTime != null &&
                !reactionTime.isAfter(chat.lastMessageTime!)) {
              return chat;
            }

            final msgId =
                reactionRow[MessageReactionColumns.messageId] as String?;
            final msg = msgId != null ? messagesById[msgId] : null;
            if (msg == null) return chat;

            final reactorId =
                reactionRow[MessageReactionColumns.userId] as String? ?? '';
            final isMe = reactorId == currentUserId;
            final reactionEmoji =
                reactionRow[MessageReactionColumns.reaction] as String?;

            final previewText =
                MessageReactionPreviewHelper.formatReactionPreview(
                  isMe: isMe,
                  reactorName: chat.name,
                  reactionType: reactionEmoji,
                  messageType: msg[MessagesColumns.messageType] as String?,
                  messageText: msg[MessagesColumns.messageText] as String?,
                  fileName: msg[MessagesColumns.fileName] as String?,
                  caption: msg[MessagesColumns.caption] as String?,
                );

            return chat.copyWith(
              lastMessage: previewText,
              lastMessageType: 'message_react',
              lastMessageTime: reactionTime,
              lastMessageIsMe: isMe,
            );
          }).toList();

      updated.sort((a, b) {
        final aTime =
            a.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime =
            b.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      return updated;
    } catch (e) {
      debugPrint('⚠️ _enrichWithLatestReactions failed (non-fatal): $e');
      return chats;
    }
  }

  Stream<void> getChatsStream(String currentUserId) {
    final controller = StreamController<void>.broadcast();

    final channelName = 'chats_$currentUserId';

    _supabase.removeChannel(_supabase.channel(channelName));

    final channel = _supabase.channel(channelName);

    void notify(PostgresChangePayload _) {
      if (!controller.isClosed) controller.add(null);
    }

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseConstants.messages,
          callback: notify,
        )
        .onPostgresChanges(
          schema: 'public',
          table: SupabaseConstants.typingStatus,
          event: PostgresChangeEvent.all,
          callback: notify,
        )
        .onPostgresChanges(
          schema: 'public',
          table: SupabaseConstants.userPresence,
          event: PostgresChangeEvent.all,
          callback: notify,
        )
        .subscribe();

    controller.onCancel = () {
      _supabase.removeChannel(channel);
      controller.close();
    };

    return controller.stream;
  }
}

class ReceiverPushInfo {
  final String fcmToken;
  final String name;
  final String imageUrl;

  const ReceiverPushInfo({
    required this.fcmToken,
    required this.name,
    required this.imageUrl,
  });
}
