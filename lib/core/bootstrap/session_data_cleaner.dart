import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/adapters.dart';
import '../../features/ai_assistant/services/ai_preferences_store.dart';
import '../../features/ai_chat/di/ai_chat_dependencies.dart';
import '../../features/ai_chat/models/ai_chat_message_record.dart';
import '../../features/ai_chat/models/ai_chat_session.dart';
import '../../features/reels/services/reels_preferences_store.dart';
import '../cache/constants/hive_box_names.dart';
import '../cache/services/hive_cache_manager.dart';
import '../cache/services/local_snapshot_store.dart';
import '../cache/services/starred_message_store.dart';

/// Single place that decides what happens to on-device data when an account
/// session ends. Local data falls in three classes:

abstract final class SessionDataCleaner {
  /// Called on every session end (see `_resetSessionCubits`).
  static Future<void> clearOnSessionEnd() async {
    await Future.wait([
      _guard('data snapshots', LocalSnapshotStore.instance.clearAll),
      _guard(
        'account-scoped hive cache',
        HiveCacheManager.instance.clearUserScopedData,
      ),
      _guard('syncra chat mirror', _clearAiChatMirror),
      _guard('ai usage', _clearAiUsage),
    ]);
  }

  /// Account deletion = session end + removal of the user-scoped local data.
  static Future<void> clearOnAccountDeletion(String? userId) async {
    await clearOnSessionEnd();
    if (userId == null || userId.isEmpty) return;
    await Future.wait([
      _guard(
        'starred messages',
        () => StarredMessagesStore.instance.clearForUser(userId),
      ),
      _guard(
        'reels preferences',
        () => ReelsPreferencesStore.instance.clearForUser(userId),
      ),
    ]);
  }

  static Future<void> _clearAiChatMirror() async {
    if (Hive.isBoxOpen(HiveBoxNames.aiChatSessions)) {
      await Hive.box<AiChatSession>(HiveBoxNames.aiChatSessions).clear();
    } else {
      await Hive.deleteBoxFromDisk(HiveBoxNames.aiChatSessions);
    }

    if (Hive.isBoxOpen(HiveBoxNames.aiChatMessages)) {
      await Hive.box<AiChatMessageRecord>(HiveBoxNames.aiChatMessages).clear();
    } else {
      await Hive.deleteBoxFromDisk(HiveBoxNames.aiChatMessages);
    }
  }

  static Future<void> _clearAiUsage() async {
    await AiPreferencesStore.instance.clearCachedUsage();
    await AiChatDependencies.resetSession();
  }

  static Future<void> _guard(
    String label,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (error) {
      debugPrint('⚠️ SessionDataCleaner "$label" failed: $error');
    }
  }
}
