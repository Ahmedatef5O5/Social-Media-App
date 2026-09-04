import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/presence/models/chat_action_type.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/utilities/supabase_constants.dart';
import '../models/group_presence_entry.dart';

class GroupPresenceService {
  final _supabase = SupabaseProvider.client;

  String get currentUserId => SupabaseProvider.id;

  static const int _presenceStaleAfterSeconds = 5;
  static const int _presenceWatchdogTickSeconds = 2;

  Stream<Map<String, GroupPresenceSnapshot>> watchAllGroupsPresence() {
    final controller =
        StreamController<Map<String, GroupPresenceSnapshot>>.broadcast();
    List<Map<String, dynamic>> latestRows = const [];

    final Map<String, Map<String, String?>> userCache = {};
    final Map<String, DateTime> localReceiveTime = {};
    final Map<String, String> lastUpdatedAt = {};

    Future<Map<String, GroupPresenceSnapshot>> computeSnapshot() async {
      final now = DateTime.now();
      final nowUtc = now.toUtc();
      final Map<String, Map<ChatActionType, List<GroupPresenceEntry>>> grouped =
          {};

      for (final row in latestRows) {
        final actionType = ChatActionTypeX.fromValue(row['action_type']);
        if (actionType == ChatActionType.none) continue;

        final groupId = row[GroupTypingColumns.groupId] as String;
        final userId = row[GroupTypingColumns.userId] as String;
        if (userId == currentUserId) continue;

        final updatedAtRaw = row[GroupTypingColumns.updatedAt];
        if (updatedAtRaw != null) {
          final updatedAt = DateTime.parse(updatedAtRaw.toString()).toUtc();
          if (nowUtc.difference(updatedAt).inMinutes > 5) {
            continue;
          }
        }

        if (!localReceiveTime.containsKey(userId)) continue;
        final receivedAt = localReceiveTime[userId]!;
        if (now.difference(receivedAt).inSeconds > _presenceStaleAfterSeconds) {
          continue;
        }

        if (!userCache.containsKey(userId)) {
          try {
            final data =
                await _supabase
                    .from('users')
                    .select('name, image_url')
                    .eq('id', userId)
                    .maybeSingle();
            userCache[userId] = {
              'name': data?['name'] as String? ?? 'Someone',
              'avatar': data?['image_url'] as String?,
            };
          } catch (_) {
            userCache[userId] = {'name': 'Someone', 'avatar': null};
          }
        }

        final userInfo = userCache[userId]!;
        grouped.putIfAbsent(groupId, () => {});
        grouped[groupId]!.putIfAbsent(actionType, () => []);
        grouped[groupId]![actionType]!.add(
          GroupPresenceEntry(
            userId: userId,
            userName: userInfo['name'] ?? 'Someone',
            userAvatar: userInfo['avatar'],
            actionType: actionType,
          ),
        );
      }
      return grouped.map((k, v) => MapEntry(k, GroupPresenceSnapshot(v)));
    }

    void emit() async {
      if (controller.isClosed) return;
      controller.add(await computeSnapshot());
    }

    final sub = SupabaseProvider.client
        .from(SupabaseConstants.groupTypingStatus)
        .stream(
          primaryKey: [GroupTypingColumns.groupId, GroupTypingColumns.userId],
        )
        .listen(
          (rows) {
            for (final row in rows) {
              final uId = row[GroupTypingColumns.userId] as String;
              if (row['action_type'] != 'none') {
                final updatedAtStr =
                    row[GroupTypingColumns.updatedAt]?.toString() ?? '';
                if (lastUpdatedAt[uId] != updatedAtStr) {
                  localReceiveTime[uId] = DateTime.now();
                  lastUpdatedAt[uId] = updatedAtStr;
                }
              }
            }
            latestRows = rows;
            emit();
          },
          onError:
              (e) => debugPrint('[watchAllGroupsPresence] stream error: $e'),
        );

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

  Future<void> setGroupAction(
    String groupId,
    ChatActionType actionType, {
    required bool isMember,
  }) async {
    if (!isMember) return;
    try {
      await _supabase.from(SupabaseConstants.groupTypingStatus).upsert(
        {
          GroupTypingColumns.groupId: groupId,
          GroupTypingColumns.userId: currentUserId,
          'action_type': actionType.value,
          GroupTypingColumns.updatedAt:
              DateTime.now().toUtc().toIso8601String(),
        },
        onConflict:
            '${GroupTypingColumns.groupId},${GroupTypingColumns.userId}',
      );
    } catch (e) {
      debugPrint('[setGroupAction] FAILED to write presence: $e');
    }
  }

  Stream<GroupPresenceSnapshot> watchGroupPresence(String groupId) {
    final controller = StreamController<GroupPresenceSnapshot>.broadcast();
    List<Map<String, dynamic>> latestRows = const [];

    final Map<String, Map<String, String?>> userCache = {};
    final Map<String, DateTime> localReceiveTime = {};
    final Map<String, String> lastUpdatedAt = {};

    Future<GroupPresenceSnapshot> computeSnapshot() async {
      final Map<ChatActionType, List<GroupPresenceEntry>> grouped = {};
      final now = DateTime.now();
      final nowUtc = now.toUtc();

      for (final row in latestRows) {
        final actionType = ChatActionTypeX.fromValue(row['action_type']);
        if (actionType == ChatActionType.none) continue;

        final userId = row[GroupTypingColumns.userId] as String;
        if (userId == currentUserId) continue;

        final updatedAtRaw = row[GroupTypingColumns.updatedAt];
        if (updatedAtRaw != null) {
          final updatedAt = DateTime.parse(updatedAtRaw.toString()).toUtc();
          if (nowUtc.difference(updatedAt).inMinutes > 5) {
            continue;
          }
        }

        if (!localReceiveTime.containsKey(userId)) continue;
        final receivedAt = localReceiveTime[userId]!;
        if (now.difference(receivedAt).inSeconds > _presenceStaleAfterSeconds) {
          continue;
        }

        if (!userCache.containsKey(userId)) {
          try {
            final data =
                await _supabase
                    .from('users')
                    .select('name, image_url')
                    .eq('id', userId)
                    .maybeSingle();
            userCache[userId] = {
              'name': data?['name'] as String? ?? 'Someone',
              'avatar': data?['image_url'] as String?,
            };
          } catch (_) {
            userCache[userId] = {'name': 'Someone', 'avatar': null};
          }
        }

        final userInfo = userCache[userId]!;
        grouped.putIfAbsent(actionType, () => []);
        grouped[actionType]!.add(
          GroupPresenceEntry(
            userId: userId,
            userName: userInfo['name'] ?? 'Someone',
            userAvatar: userInfo['avatar'],
            actionType: actionType,
          ),
        );
      }
      return GroupPresenceSnapshot(grouped);
    }

    void emit() async {
      if (controller.isClosed) return;
      controller.add(await computeSnapshot());
    }

    final sub = _supabase
        .from(SupabaseConstants.groupTypingStatus)
        .stream(
          primaryKey: [GroupTypingColumns.groupId, GroupTypingColumns.userId],
        )
        .eq(GroupTypingColumns.groupId, groupId)
        .listen((rows) {
          for (final row in rows) {
            final uId = row[GroupTypingColumns.userId] as String;
            if (row['action_type'] != 'none') {
              final updatedAtStr =
                  row[GroupTypingColumns.updatedAt]?.toString() ?? '';
              if (lastUpdatedAt[uId] != updatedAtStr) {
                localReceiveTime[uId] = DateTime.now();
                lastUpdatedAt[uId] = updatedAtStr;
              }
            }
          }
          latestRows = rows;
          emit();
        }, onError: (e) => debugPrint('[watchGroupPresence] stream error: $e'));

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
}
