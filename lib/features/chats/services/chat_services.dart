import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:social_media_app/core/secrets/app_secrets.dart';
import 'package:social_media_app/core/utilities/supabase_constants.dart';
import 'package:social_media_app/features/chats/models/message_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_user_model.dart';

class ChatServices {
  final _supabase = Supabase.instance.client;

  Future<bool> isConnected() async {
    return await InternetConnection().hasInternetAccess;
  }

  Future<List<ChatUserModel>> getChatsList(String currentUserId) async {

    if (!(await isConnected())) {
      throw Exception('no-internet');
    }
    
    try {
      final response = await _supabase.rpc(
        SupabaseConstants.getChatsWithLastMessage,
        params: {'current_user_id': currentUserId},
      );

      if (response == null) return [];
      return (response as List)
          .map(((data) => ChatUserModel.fromUserData(data, currentUserId)))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getChatsStream(String currentUserId) {
    final controller = StreamController<List<Map<String, dynamic>>>();

    final channelName =
        'chats_updates_${currentUserId}_${DateTime.now().millisecondsSinceEpoch}';
    final combinedChannel = _supabase.channel(channelName);

    void notify(PostgresChangePayload payload) {
      if (!controller.isClosed) {
        debugPrint('Realtime Change Detected in: ${payload.table}');
        controller.add([]);
      }
    }

    combinedChannel
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
          table: SupabaseConstants.users,
          event: PostgresChangeEvent.update,
          callback: notify,
        );

    controller.onListen = () {
      combinedChannel.subscribe((status, [error]) {
        if (status == RealtimeSubscribeStatus.channelError) {
          debugPrint('Detailed Realtime Error: $error');
        }
      });
    };

    controller.onCancel = () {
      _supabase.removeChannel(combinedChannel);
      controller.close();
    };

    return controller.stream;
  }

  Stream<List<MessageModel>> getMessagesStream({
    required String senderId,
    required String receiverId,
  }) {
    return _supabase
        .from(SupabaseConstants.messages)
        .stream(primaryKey: [MessagesColumns.id])
        .order(MessagesColumns.createdAt, ascending: false)
        .map(
          (data) =>
              data
                  .map((map) => MessageModel.fromJson(map))
                  .where(
                    (msg) =>
                        (msg.senderId == senderId &&
                            msg.receiverId == receiverId) ||
                        (msg.senderId == receiverId &&
                            msg.receiverId == senderId),
                  )
                  .toList(),
        );
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
    });
  }

  Future<void> deleteMessage({required String messageId}) async {
    await _supabase
        .from(SupabaseConstants.messages)
        .delete()
        .eq(MessagesColumns.id, messageId);
  }

  Future<void> addReaction({
    required String messageId,
    required String reaction,
    required String currentReaction,
  }) async {
    await _supabase
        .from(SupabaseConstants.messages)
        .update({
          MessagesColumns.reaction:
              currentReaction == reaction ? null : reaction,
        })
        .eq(MessagesColumns.id, messageId);
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

  Future<String> uploadChatFile(
    File file,
    String type, {
    Function(double)? onProgress,
    dio_pkg.CancelToken? cancelToken,
  }) async {
    if (!await file.exists()) {
      throw Exception('File not found at path: ${file.path}');
    }

    final ext = file.path.split('.').last.toLowerCase();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final uploadPath = '$type/$fileName';

    String contentType;
    if (type == 'image') {
      contentType = 'image/${(ext == 'jpg' || ext == 'jpeg') ? 'jpeg' : ext}';
    } else if (type == 'video') {
      contentType = ext == 'mov' ? 'video/quicktime' : 'video/mp4';
    } else if (type == 'voice') {
      contentType =
          (ext == 'm4a' || ext == 'aac') ? 'audio/x-m4a' : 'audio/mpeg';
    } else {
      contentType = 'application/octet-stream';
    }

    final storageBaseUrl = '${AppSecrets.supabaseUrl}/storage/v1';
    final accessToken =
        _supabase.auth.currentSession?.accessToken ??
        AppSecrets.supabaseAnonKey;
    final fileLength = await file.length();

    final dioClient = dio_pkg.Dio();

    try {
      onProgress?.call(0.01);

      await dioClient.put(
        '$storageBaseUrl/object/chat_media/$uploadPath',
        data: file.openRead(),
        cancelToken: cancelToken,
        options: dio_pkg.Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': contentType,
            'x-upsert': 'false',
            'Content-Length': fileLength.toString(),
          },
        ),
        onSendProgress: (sent, total) {
          if (total > 0 && onProgress != null) {
            final progress = (sent / total).clamp(0.0, 1.0);
            onProgress(progress);
          }
        },
      );

      onProgress?.call(1.0);

      return _supabase.storage.from('chat_media').getPublicUrl(uploadPath);
    } catch (e) {
      if (dio_pkg.DioExceptionType.cancel == (e as dio_pkg.DioException).type) {
        debugPrint('Upload Canceled by user');
        throw Exception('CANCELED');
      }

      throw Exception('Upload failed: $e');
    }
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

          return receiverRow.isNotEmpty &&
              receiverRow.first[TypingStatusColumns.isTyping] == true;
        });
  }

  Stream<List<String>> getTypingUsersStream(String currentUserId) {
    return _supabase
        .from(SupabaseConstants.typingStatus)
        .stream(
          primaryKey: [TypingStatusColumns.chatId, TypingStatusColumns.userId],
        )
        .map((rows) {
          return rows
              .where(
                (row) =>
                    row[TypingStatusColumns.isTyping] == true &&
                    (row[TypingStatusColumns.chatId] as String).contains(
                      currentUserId,
                    ) &&
                    row[TypingStatusColumns.userId] != currentUserId,
              )
              .map((row) => row[TypingStatusColumns.userId] as String)
              .toList();
        });
  }
}
