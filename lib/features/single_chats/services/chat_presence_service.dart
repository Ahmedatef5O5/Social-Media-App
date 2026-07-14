import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/presence_service.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/utilities/supabase_constants.dart';
import '../models/presence_snapshot.dart';

class ChatPresenceService {
  final _supabase = SupabaseProvider.client;

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
}
