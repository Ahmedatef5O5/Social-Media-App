import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/material.dart';
import 'package:social_media_app/core/secrets/app_secrets.dart';
import 'package:social_media_app/core/utilities/supabase_constants.dart';
import 'package:social_media_app/features/chats/models/message_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_user_model.dart';

class ChatServices {
  final _supabase = Supabase.instance.client;

  Future<List<ChatUserModel>> getChatsList(String currentUserId) async {
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
      debugPrint('Error in getChatsList RPC: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getChatsStream(String currentUserId) {
    final controller = StreamController<List<Map<String, dynamic>>>();

    final channel = _supabase.channel('chats_updates_$currentUserId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseConstants.messages,
          callback: (payload) {
            if (!controller.isClosed) {
              controller.add([]);
            }
          },
        )
        .subscribe((status, error) {
          if (error != null) {
            debugPrint('Realtime Channel Error: $error');
          }
        });

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
    });
  }

  Future<void> deleteMessage({required String messageId}) async {
    await _supabase
        .from(SupabaseConstants.messages)
        .delete()
        .eq('id', messageId);
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

  Stream<DateTime?> getLastSeenStream(String userId) {
    return _supabase
        .from(SupabaseConstants.users)
        .stream(primaryKey: [UserColumns.id])
        .eq('id', userId)
        .map((data) {
          if (data.isEmpty || data.first['last_seen'] == null) {
            return null;
          }
          return DateTime.parse(data.first['last_seen']);
        });
  }
}
