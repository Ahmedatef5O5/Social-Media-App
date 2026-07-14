import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/network_status_service.dart';
import '../../../core/services/presence_service.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/utilities/supabase_constants.dart';
import '../models/chat_user_model.dart';

/// Chat-list-level concerns: FCM push info for a receiver, the chats list
/// itself (with online-status enrichment), and a stream that fires
/// whenever anything relevant to the chats list changes.
///
/// Extracted from the monolithic `ChatServices`, which mixed this together
/// with per-conversation messages, reactions, and presence/typing. Logic is
/// unchanged — this is a pure structural extraction.
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
