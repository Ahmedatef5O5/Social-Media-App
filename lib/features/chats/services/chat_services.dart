import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:social_media_app/core/utilities/supabase_constants.dart';
import 'package:social_media_app/features/chats/models/message_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_user_model.dart';

class ChatServices {
  final _supabase = Supabase.instance.client;

  Future<List<ChatUserModel>> getChatsList(String currentUserId) async {
    // final response = await _supabase
    //     .from('users')
    //     .select()
    //     .neq('id', currentUserId);

    // final List<ChatUserModel> res = [];
    // for (final user in response as List) {
    //   final userId = user['id'] as String;

    //   final lastMsgResponse =
    //       await _supabase
    //           .from(SupabaseConstants.messages)
    //           .select('message_text, message_type, created_at')
    //           .or(
    //             'and(sender_id.eq.$currentUserId,receiver_id.eq.$userId),and(sender_id.eq.$userId,receiver_id.eq.$currentUserId)',
    //           )
    //           .order(MessagesColumns.createdAt, ascending: false)
    //           .limit(1)
    //           .maybeSingle();

    //   final unreadResponse = await _supabase
    //       .from('messages')
    //       .select()
    //       .eq('sender_id', userId)
    //       .eq('receiver_id', currentUserId)
    //       .eq('is_read', false);

    //   res.add(
    //     ChatUserModel(
    //       id: userId,
    //       name: user['name'] as String? ?? 'Unknown',
    //       imageUrl: user['image_url'] as String? ?? '',
    //       lastMessage: lastMsgResponse?['message_text'] as String? ?? '',
    //       lastMessageType: lastMsgResponse?['message_type'] ?? 'text',
    //       lastMessageTime:
    //           lastMsgResponse?['created_at'] != null
    //               ? DateTime.parse(lastMsgResponse?['created_at'])
    //               : null,
    //       unreadCount: (unreadResponse as List).length,
    //       lastSeen:
    //           user['last_seen'] != null
    //               ? DateTime.parse(user['last_seen'])
    //               : null,
    //     ),
    //   );
    // }
    // res.sort((a, b) {
    //   if (a.lastMessageTime == null && b.lastMessageTime == null) return 0;
    //   if (a.lastMessageTime == null) return 1;
    //   if (b.lastMessageTime == null) return -1;
    //   return b.lastMessageTime!.compareTo(a.lastMessageTime!);
    // });

    // return res;

    try {
      final response = await _supabase.rpc(
        SupabaseConstants.getChatsWithLastMessage,
        params: {'current_user_id': currentUserId},
      );

      // print('RPC response: $response');

      if (response == null) return [];
      return (response as List)
          .map(((data) => ChatUserModel.fromUserData(data, currentUserId)))
          .toList();
    } catch (e) {
      debugPrint('Error in getChatsList RPC: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getChatsStream() {
    return _supabase
        .from(SupabaseConstants.messages)
        .stream(primaryKey: [MessagesColumns.id]);
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

  Future<String> uploadChatFile(File file, String type) async {
    File fileToUpload = file;
    if (!await fileToUpload.exists()) {
      throw Exception('File not found at path: ${file.path}');
    }
    final dir = await getApplicationDocumentsDirectory();
    final ext = file.path.split('.').last;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final safePath = '${dir.path}/$fileName';
    fileToUpload = await file.copy(safePath);

    final uploadPath = '$type/$fileName';
    await _supabase.storage.from('chat_media').upload(uploadPath, fileToUpload);
    await fileToUpload.delete();

    return _supabase.storage.from('chat_media').getPublicUrl(uploadPath);
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
