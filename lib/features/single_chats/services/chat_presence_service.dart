import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/presence/models/chat_action_type.dart';
import '../../../core/presence/services/presence_service.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/utilities/supabase_constants.dart';
import '../models/presence_snapshot.dart';

class ChatPresenceService {
  final _supabase = SupabaseProvider.client;

  Future<DateTime?> getUserLastSeen(String userId) async {
    try {
      final data =
          await _supabase
              .from(SupabaseConstants.userPresence)
              .select(PresenceColumns.lastSeen)
              .eq(PresenceColumns.userId, userId)
              .maybeSingle();
      final raw = data?[PresenceColumns.lastSeen];
      if (raw == null) return null;
      return DateTime.parse(raw.toString());
    } catch (_) {
      return null;
    }
  }

  Stream<DateTime?> getLastSeenStream(String userId) {
    return _supabase
        .from(SupabaseConstants.userPresence)
        .stream(primaryKey: [PresenceColumns.userId])
        .eq(PresenceColumns.userId, userId)
        .map((data) {
          if (data.isEmpty || data.first[PresenceColumns.lastSeen] == null) {
            return null;
          }
          return DateTime.parse(
            data.first[PresenceColumns.lastSeen].toString(),
          );
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
            lastSeenRaw != null ? DateTime.parse(lastSeenRaw.toString()) : null;

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

  Future<void> setAction({
    required String chatId,
    required String currentUserId,
    required ChatActionType actionType,
  }) async {
    try {
      await _supabase.from(SupabaseConstants.typingStatus).upsert(
        {
          TypingStatusColumns.chatId: chatId,
          TypingStatusColumns.userId: currentUserId,
          TypingStatusColumns.isTyping: actionType == ChatActionType.typing,
          'action_type': actionType.value,
          TypingStatusColumns.updatedAt:
              DateTime.now().toUtc().toIso8601String(),
        },
        onConflict:
            '${TypingStatusColumns.chatId},${TypingStatusColumns.userId}',
      );
    } catch (e) {
      debugPrint('[setAction] FAILED to write presence: $e');
    }
  }

  static const int _presenceStaleAfterSeconds = 5;
  static const int _presenceWatchdogTickSeconds = 2;

  Stream<ChatActionType> getActionStream({
    required String chatId,
    required String receiverId,
  }) {
    final controller = StreamController<ChatActionType>.broadcast();
    List<Map<String, dynamic>> latestRows = const [];
    DateTime? localReceiveTime;
    String? lastUpdatedAtStr;
    bool hasProcessedInitialSnapshot = false;

    ChatActionType computeCurrent() {
      final row = latestRows.where(
        (r) => r[TypingStatusColumns.userId] == receiverId,
      );
      if (row.isEmpty) return ChatActionType.none;

      final actionType = ChatActionTypeX.fromValue(row.first['action_type']);
      if (actionType == ChatActionType.none) return ChatActionType.none;

      final updatedAtRaw = row.first[TypingStatusColumns.updatedAt];
      if (updatedAtRaw != null) {
        final updatedAt = DateTime.tryParse(updatedAtRaw.toString())?.toUtc();
        if (updatedAt != null &&
            DateTime.now().toUtc().difference(updatedAt).abs().inMinutes > 10) {
          return ChatActionType.none;
        }
      }

      if (localReceiveTime == null) return ChatActionType.none;
      if (DateTime.now().difference(localReceiveTime!).inSeconds >
          _presenceStaleAfterSeconds) {
        return ChatActionType.none;
      }

      return actionType;
    }

    ChatActionType? lastEmitted;
    void emit() {
      if (controller.isClosed) return;
      final current = computeCurrent();
      if (current == lastEmitted) return;
      lastEmitted = current;
      controller.add(current);
    }

    final sub = _supabase
        .from(SupabaseConstants.typingStatus)
        .stream(
          primaryKey: [TypingStatusColumns.chatId, TypingStatusColumns.userId],
        )
        .eq(TypingStatusColumns.chatId, chatId)
        .listen((rows) {
          final now = DateTime.now();
          final nowUtc = now.toUtc();
          final receiverRows = rows.where(
            (r) => r[TypingStatusColumns.userId] == receiverId,
          );

          if (receiverRows.isNotEmpty) {
            final row = receiverRows.first;
            final actionType = ChatActionTypeX.fromValue(row['action_type']);
            final updatedAtStr =
                row[TypingStatusColumns.updatedAt]?.toString() ?? '';

            if (actionType == ChatActionType.none) {
              localReceiveTime = null;
              lastUpdatedAtStr = updatedAtStr;
            } else if (!hasProcessedInitialSnapshot) {
              lastUpdatedAtStr = updatedAtStr;
              final parsed = DateTime.tryParse(updatedAtStr)?.toUtc();
              if (parsed != null &&
                  nowUtc.difference(parsed).abs().inSeconds <=
                      _presenceStaleAfterSeconds) {
                localReceiveTime = now;
              }
            } else if (lastUpdatedAtStr != updatedAtStr) {
              localReceiveTime = now;
              lastUpdatedAtStr = updatedAtStr;
            }
          } else {
            localReceiveTime = null;
          }

          hasProcessedInitialSnapshot = true;
          latestRows = rows;
          emit();
        }, onError: (e) => debugPrint('[getActionStream] stream error: $e'));

    final watchdog = Timer.periodic(
      const Duration(seconds: _presenceWatchdogTickSeconds),
      (_) => emit(),
    );

    controller.onCancel = () {
      sub.cancel();
      watchdog.cancel();
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

  Stream<Map<String, ChatActionType>> getGlobalActionsStream(
    String currentUserId,
  ) {
    final controller =
        StreamController<Map<String, ChatActionType>>.broadcast();

    final Map<
      String,
      ({String userId, ChatActionType action, DateTime receivedAt})
    >
    byChatId = {};

    Map<String, ChatActionType> computeCurrent() {
      final now = DateTime.now();
      byChatId.removeWhere(
        (_, v) =>
            now.difference(v.receivedAt).inSeconds > _presenceStaleAfterSeconds,
      );
      return {for (final v in byChatId.values) v.userId: v.action};
    }

    Map<String, ChatActionType> lastEmitted = const {};
    void emitIfChanged() {
      if (controller.isClosed) return;
      final current = computeCurrent();
      if (mapEquals(current, lastEmitted)) return;
      lastEmitted = current;
      controller.add(current);
    }

    const channelName = 'global_actions_watcher';
    _supabase.removeChannel(_supabase.channel(channelName));

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

                final actionType = ChatActionTypeX.fromValue(
                  record['action_type'] as String?,
                );
                final updatedAtRaw =
                    record[TypingStatusColumns.updatedAt] as String?;
                final updatedAt =
                    updatedAtRaw != null
                        ? DateTime.tryParse(updatedAtRaw)?.toUtc()
                        : null;

                final isFreshEnough =
                    updatedAt == null ||
                    DateTime.now()
                            .toUtc()
                            .difference(updatedAt)
                            .abs()
                            .inMinutes <=
                        10;

                if (actionType != ChatActionType.none && isFreshEnough) {
                  byChatId[chatId] = (
                    userId: userId,
                    action: actionType,
                    receivedAt: DateTime.now(),
                  );
                } else {
                  byChatId.remove(chatId);
                }

                emitIfChanged();
              },
            )
            .subscribe();

    final watchdog = Timer.periodic(
      const Duration(seconds: _presenceWatchdogTickSeconds),
      (_) => emitIfChanged(),
    );

    controller.onCancel = () {
      _supabase.removeChannel(channel);
      watchdog.cancel();
      controller.close();
    };

    return controller.stream;
  }
}
