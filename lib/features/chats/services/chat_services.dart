import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/material.dart';
import 'package:social_media_app/core/secrets/app_secrets.dart';
import 'package:social_media_app/core/services/presence_service.dart';
import 'package:social_media_app/core/utilities/supabase_constants.dart';
import 'package:social_media_app/features/chats/models/message_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_user_model.dart';
import '../models/presence_snapshot.dart';

class ChatServices {
  final _supabase = Supabase.instance.client;

  Future<bool> isConnected() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

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
    if (!(await isConnected())) {
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
          .from('user_presence')
          .select('user_id, is_online, updated_at')
          .inFilter('user_id', userIds);

      final onlineSet = <String>{
        for (final row in presenceRows as List)
          if (PresenceService.isConsideredOnline(
            isOnline: row['is_online'] as bool? ?? false,
            updatedAt:
                row['updated_at'] != null
                    ? DateTime.parse(row['updated_at'].toString())
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
          table: 'user_presence',
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

  Stream<PresenceSnapshot> getPresenceStream(String userId) {
    final controller = StreamController<PresenceSnapshot>();

    Future<void> fetchAndEmit() async {
      try {
        final rows = await _supabase
            .from('user_presence')
            .select('is_online, last_seen, updated_at')
            .eq('user_id', userId)
            .limit(1);

        if (controller.isClosed) return;

        if (rows == null || (rows as List).isEmpty) {
          controller.add(
            const PresenceSnapshot(isOnline: false, lastSeen: null),
          );
          return;
        }

        final row = rows.first as Map<String, dynamic>;

        final updatedAtRaw = row['updated_at'];
        final updatedAt =
            updatedAtRaw != null
                ? DateTime.parse(updatedAtRaw.toString())
                : null;
        final isOnline = PresenceService.isConsideredOnline(
          isOnline: row['is_online'] as bool? ?? false,
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
              table: 'user_presence',
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
    return _supabase
        .from(SupabaseConstants.typingStatus)
        .stream(
          primaryKey: [TypingStatusColumns.chatId, TypingStatusColumns.userId],
        )
        .map((rows) {
          final now = DateTime.now().toUtc();

          return rows
              .where((row) {
                if (row[TypingStatusColumns.isTyping] != true) return false;
                if (!(row[TypingStatusColumns.chatId] as String).contains(
                  currentUserId,
                )) {
                  return false;
                }
                if (row[TypingStatusColumns.userId] == currentUserId) {
                  return false;
                }

                final updatedAtRaw = row[TypingStatusColumns.updatedAt];
                if (updatedAtRaw != null) {
                  final updatedAt =
                      DateTime.parse(updatedAtRaw.toString()).toUtc();
                  if (now.difference(updatedAt).inSeconds > 4) {
                    return false; // الحالة معلقة، تجاهلها
                  }
                }
                return true;
              })
              .map((row) => row[TypingStatusColumns.userId] as String)
              .toList();
        });
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
