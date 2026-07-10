import 'dart:async';
import 'package:flutter/material.dart';
import 'package:social_media_app/core/services/cloudinary_storage_services.dart';
import 'package:social_media_app/core/services/presence_service.dart';
import 'package:social_media_app/core/utilities/supabase_constants.dart';
import 'package:social_media_app/features/single_chats/models/message_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/helpers/chat_helper.dart';
import '../../../core/services/media_cleanup_service.dart';
import '../../../core/services/network_status_service.dart';
import '../models/chat_user_model.dart';
import '../models/presence_snapshot.dart';

class ChatServices {
  final _supabase = Supabase.instance.client;
  final NetworkStatusService _networkStatus;

  ChatServices({NetworkStatusService? networkStatus})
    : _networkStatus = networkStatus ?? NetworkStatusService.instance;

  CloudinaryStorageServices get storage => CloudinaryStorageServices.instance;

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

      return chats
          .map((c) => c.copyWith(isOnline: onlineSet.contains(c.id)))
          .toList();
    } catch (e) {
      rethrow;
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

  Stream<List<MessageModel>> getMessagesStream({
    required String senderId,
    required String receiverId,
  }) {
    final conversationId = ChatHelper.buildConversationId(senderId, receiverId);

    return _supabase
        .from(SupabaseConstants.messages)
        .stream(primaryKey: [MessagesColumns.id])
        .eq(MessagesColumns.conversationId, conversationId)
        .order(MessagesColumns.createdAt, ascending: false)
        .map(
          (data) =>
              data
                  .map(MessageModel.fromJson)
                  .where((m) => !m.deletedFor.contains(senderId))
                  .toList(),
        );
  }

  Future<List<Map<String, dynamic>>> getChatMedia(String receiverId) async {
    final currentUserId = _supabase.auth.currentUser!.id;

    try {
      final response = await _supabase
          .from(SupabaseConstants.messages)
          .select(
            '${MessagesColumns.imageUrl}, ${MessagesColumns.videoUrl}, ${MessagesColumns.voiceUrl}, ${MessagesColumns.messageType}',
          )
          .or(
            '${MessagesColumns.senderId}.eq.$currentUserId,${MessagesColumns.senderId}.eq.$receiverId',
          )
          .or(
            '${MessagesColumns.receiverId}.eq.$currentUserId,${MessagesColumns.receiverId}.eq.$receiverId',
          )
          .filter(MessagesColumns.messageType, 'in', [
            'image',
            'video',
            'voice',
          ])
          .order(MessagesColumns.createdAt, ascending: false);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error fetching media: $e');
      return [];
    }
  }

  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
    String messageType = 'text',
    String? imageUrl,
    String? videoUrl,
    String? voiceUrl,
    String? caption,
    String? replyToMessageId,
    String? replyToText,
    String? replyToMessageType,
    String? replyToSenderId,
    String? imagePublicId,
    String? videoPublicId,
    String? voicePublicId,
    String? replyToStoryId,
    String? replyToStoryAuthorId,
    String? replyToStoryType,
    String? replyToStoryMediaUrl,
    String? replyToStoryText,
    String? replyToStoryBgColor,
    int? replyToStoryDurationSeconds,
  }) async {
    await _supabase.from(SupabaseConstants.messages).insert({
      MessagesColumns.senderId: senderId,
      MessagesColumns.receiverId: receiverId,
      MessagesColumns.messageText: text,
      MessagesColumns.messageType: messageType,
      if (imageUrl != null) MessagesColumns.imageUrl: imageUrl,
      if (videoUrl != null) MessagesColumns.videoUrl: videoUrl,
      if (voiceUrl != null) MessagesColumns.voiceUrl: voiceUrl,
      if (caption != null) MessagesColumns.caption: caption,
      if (replyToMessageId != null)
        MessagesColumns.replyToMessageId: replyToMessageId,
      if (replyToText != null) MessagesColumns.replyToText: replyToText,
      if (replyToMessageType != null)
        MessagesColumns.replyToMessageType: replyToMessageType,
      if (replyToSenderId != null)
        MessagesColumns.replyToSenderId: replyToSenderId,
      if (imagePublicId != null) MessagesColumns.imagePublicId: imagePublicId,
      if (videoPublicId != null) MessagesColumns.videoPublicId: videoPublicId,
      if (voicePublicId != null) MessagesColumns.voicePublicId: voicePublicId,
      if (replyToStoryId != null)
        MessagesColumns.replyToStoryId: replyToStoryId,
      if (replyToStoryAuthorId != null)
        MessagesColumns.replyToStoryAuthorId: replyToStoryAuthorId,
      if (replyToStoryType != null)
        MessagesColumns.replyToStoryType: replyToStoryType,
      if (replyToStoryMediaUrl != null)
        MessagesColumns.replyToStoryMediaUrl: replyToStoryMediaUrl,
      if (replyToStoryText != null)
        MessagesColumns.replyToStoryText: replyToStoryText,
      if (replyToStoryBgColor != null)
        MessagesColumns.replyToStoryBgColor: replyToStoryBgColor,
      if (replyToStoryDurationSeconds != null)
        MessagesColumns.replyToStoryDurationSeconds:
            replyToStoryDurationSeconds,
    });
  }

  Future<void> deleteMessage({required String messageId}) async {
    await MediaCleanupService.instance.deleteWithMedia(
      table: SupabaseConstants.messages,
      id: messageId,
    );
  }

  Future<void> deleteMessagesForEveryone(List<String> messageIds) async {
    for (final id in messageIds) {
      await MediaCleanupService.instance.deleteWithMedia(
        table: SupabaseConstants.messages,
        id: id,
      );
    }
  }

  Future<void> deleteMessagesForMe({
    required List<MessageModel> messages,
    required String currentUserId,
  }) async {
    for (final m in messages) {
      final updated = {...m.deletedFor, currentUserId}.toList();
      await _supabase
          .from(SupabaseConstants.messages)
          .update({MessagesColumns.deletedFor: updated})
          .eq(MessagesColumns.id, m.id);
    }
  }

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

  Future<void> markMessagesAsRead({
    required String senderId,
    required String currentUserId,
  }) async {
    await _supabase
        .from(SupabaseConstants.messages)
        .update({MessagesColumns.isRead: true})
        .eq(MessagesColumns.senderId, senderId)
        .eq(MessagesColumns.receiverId, currentUserId)
        .eq(MessagesColumns.isRead, false);
  }

  Stream<PresenceSnapshot> getPresenceStream(String userId) {
    final controller = StreamController<PresenceSnapshot>();

    Future<void> fetchAndEmit() async {
      try {
        final rows = await _supabase
            .from(SupabaseConstants.userPresence)
            .select('is_online, last_seen, updated_at')
            .eq('user_id', userId)
            .limit(1);

        if (controller.isClosed) return;

        // ignore: unnecessary_null_comparison
        if (rows == null || (rows as List).isEmpty) {
          controller.add(
            const PresenceSnapshot(isOnline: false, lastSeen: null),
          );
          return;
        }

        // ignore: unnecessary_cast
        final row = rows.first as Map<String, dynamic>;

        final updatedAtRaw = row[PresenceColumns.updatedAt];
        final updatedAt =
            updatedAtRaw != null
                ? DateTime.parse(updatedAtRaw.toString())
                : null;
        final isOnline = PresenceService.isConsideredOnline(
          isOnline: row[PresenceColumns.isOnline] as bool? ?? false,
          updatedAt: updatedAt,
        );

        final lastSeenRaw = row['last_seen'];
        final lastSeen =
            lastSeenRaw != null
                ? DateTime.parse(lastSeenRaw.toString()).toLocal()
                : null;

        controller.add(
          PresenceSnapshot(isOnline: isOnline, lastSeen: lastSeen),
        );
      } catch (e) {
        debugPrint('getPresenceStream fetchAndEmit error: $e');
      }
    }

    fetchAndEmit();

    final channelName = 'presence_$userId';
    _supabase.removeChannel(_supabase.channel(channelName));

    final channel =
        _supabase
            .channel(channelName)
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: SupabaseConstants.userPresence,
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'user_id',
                value: userId,
              ),
              callback: (_) => fetchAndEmit(),
            )
            .subscribe();

    controller.onCancel = () {
      _supabase.removeChannel(channel);
      controller.close();
    };

    return controller.stream;
  }

  Future<void> updateLastSeen(String userId) async {
    try {
      await _supabase
          .from(SupabaseConstants.users)
          .update({
            UserColumns.lastSeen: DateTime.now().toUtc().toIso8601String(),
          })
          .eq(UserColumns.id, userId);
    } catch (e) {
      debugPrint('error updating last seen: $e');
    }
  }

  Future<DateTime?> getUserLastSeen(String userId) async {
    try {
      final data =
          await _supabase
              .from(SupabaseConstants.users)
              .select(UserColumns.lastSeen)
              .eq(UserColumns.id, userId)
              .single();
      if (data[UserColumns.lastSeen] == null) return null;
      return DateTime.parse(data[UserColumns.lastSeen]);
    } catch (_) {
      return null;
    }
  }

  Stream<DateTime?> getLastSeenStream(String userId) {
    return _supabase
        .from(SupabaseConstants.users)
        .stream(primaryKey: [UserColumns.id])
        .eq(UserColumns.id, userId)
        .map((data) {
          if (data.isEmpty || data.first[UserColumns.lastSeen] == null) {
            return null;
          }
          return DateTime.parse(data.first[UserColumns.lastSeen]);
        });
  }

  Future<void> setTyping({
    required String chatId,
    required String currentUserId,
    required bool isTyping,
  }) async {
    await _supabase.from(SupabaseConstants.typingStatus).upsert({
      TypingStatusColumns.chatId: chatId,
      TypingStatusColumns.userId: currentUserId,
      TypingStatusColumns.isTyping: isTyping,
      TypingStatusColumns.updatedAt: DateTime.now().toUtc().toIso8601String(),
    });
  }

  Stream<bool> getTypingStream({
    required String chatId,
    required String receiverId,
    required String currentUserId,
  }) {
    return _supabase
        .from(SupabaseConstants.typingStatus)
        .stream(
          primaryKey: [TypingStatusColumns.chatId, TypingStatusColumns.userId],
        )
        .eq(TypingStatusColumns.chatId, chatId)
        .map((rows) {
          final receiverRow = rows.where(
            (row) => row[TypingStatusColumns.userId] == receiverId,
          );

          if (receiverRow.isEmpty) return false;

          final isTyping =
              receiverRow.first[TypingStatusColumns.isTyping] == true;
          final updatedAtRaw = receiverRow.first[TypingStatusColumns.updatedAt];

          if (isTyping && updatedAtRaw != null) {
            final updatedAt = DateTime.parse(updatedAtRaw.toString()).toUtc();
            final now = DateTime.now().toUtc();
            if (now.difference(updatedAt).inSeconds > 4) {
              return false;
            }
          }

          return isTyping;
        });
  }

  Stream<List<String>> getTypingUsersStream(String currentUserId) {
    final controller = StreamController<List<String>>.broadcast();

    final Map<String, ({String userId, DateTime updatedAt})> typingMap = {};

    const channelName = 'typing_watcher';
    _supabase.removeChannel(_supabase.channel(channelName));

    Timer? cleanupTimer;

    final channel =
        _supabase
            .channel(channelName)
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: SupabaseConstants.typingStatus,
              callback: (payload) {
                if (controller.isClosed) return;

                final record =
                    payload.eventType == PostgresChangeEvent.delete
                        ? payload.oldRecord
                        : payload.newRecord;

                final userId = record[TypingStatusColumns.userId] as String?;
                final chatId = record[TypingStatusColumns.chatId] as String?;

                if (userId == null || chatId == null) return;

                if (userId == currentUserId) return;

                final ids = chatId.split('_');
                if (!ids.contains(currentUserId)) return;

                final isTyping =
                    record[TypingStatusColumns.isTyping] as bool? ?? false;
                final updatedAtRaw =
                    record[TypingStatusColumns.updatedAt] as String?;
                final updatedAt =
                    updatedAtRaw != null
                        ? DateTime.tryParse(updatedAtRaw)?.toUtc()
                        : null;

                if (isTyping && updatedAt != null) {
                  typingMap[chatId] = (userId: userId, updatedAt: updatedAt);
                } else {
                  typingMap.remove(chatId);
                }

                controller.add(_getActiveTypers(typingMap));
              },
            )
            .subscribe();

    cleanupTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (controller.isClosed) return;
      final now = DateTime.now().toUtc();
      typingMap.removeWhere(
        (_, v) => now.difference(v.updatedAt).inSeconds > 4,
      );
      controller.add(_getActiveTypers(typingMap));
    });

    controller.onCancel = () {
      _supabase.removeChannel(channel);
      cleanupTimer?.cancel();
      controller.close();
    };

    return controller.stream;
  }

  List<String> _getActiveTypers(
    Map<String, ({String userId, DateTime updatedAt})> map,
  ) {
    final now = DateTime.now().toUtc();
    return map.entries
        .where((e) => now.difference(e.value.updatedAt).inSeconds <= 4)
        .map((e) => e.value.userId)
        .toList();
  }

  Future<Map<String, String?>> getCurrentUserInfo(String userId) async {
    try {
      final data =
          await _supabase
              .from(SupabaseConstants.users)
              .select('${UserColumns.name}, ${UserColumns.imageUrl}')
              .eq(UserColumns.id, userId)
              .single();
      return {
        'name': data[UserColumns.name] as String?,
        'imageUrl': data[UserColumns.imageUrl] as String?,
      };
    } catch (e) {
      debugPrint('Error fetching user info: $e');
      return {'name': null, 'imageUrl': null};
    }
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
