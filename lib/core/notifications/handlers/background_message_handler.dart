import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_media_app/core/cache/services/hive_cache_manager.dart';
import 'package:social_media_app/core/cache/services/local_snapshot_store.dart';
import 'package:social_media_app/core/notifications/dispatchers/chat_notification_dispatcher.dart';
import 'package:social_media_app/core/notifications/handlers/tap_action_handler.dart';
import 'package:social_media_app/core/notifications/notification_plugin_bootstrap.dart';
import 'package:social_media_app/core/secrets/app_secrets.dart';
import 'package:social_media_app/firebase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void>? _supabaseInitFuture;

Future<void> ensureSupabaseReady() {
  if (_supabaseInitFuture != null) return _supabaseInitFuture!;

  _supabaseInitFuture = () async {
    try {
      Supabase.instance.client;
      return;
    } catch (_) {}

    try {
      await Supabase.initialize(
        url: AppSecrets.supabaseUrl,
        anonKey: AppSecrets.supabaseAnonKey,
      );
    } catch (e) {
      debugPrint('[Supabase] init failed in background isolate: $e');
      _supabaseInitFuture = null;
      rethrow;
    }
  }();

  return _supabaseInitFuture!;
}

@pragma('vm:entry-point')
void onBgNotificationActionTapped(NotificationResponse response) async {
  debugPrint(
    '[NotifTap] Background action fired — actionId=${response.actionId}, payload=${response.payload}',
  );
  try {
    final actionId = response.actionId;
    if (actionId == 'reply_action' ||
        actionId == 'mark_read_action' ||
        actionId == 'mute_action') {
      await handleBackgroundChatAction(response);
      return;
    }
    // For normal taps in background, we just route it.
    TapActionHandler.handleTap(response);
  } catch (e, st) {
    debugPrint('[NotifTap] UNCAUGHT top-level error: $e\n$st');
  }
}

Future<void> _ensureFirebaseReady() async {
  try {
    Firebase.app();
  } catch (_) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

Future<void> _ensureHiveReady() async {
  try {
    final cacheDirectory = await getApplicationDocumentsDirectory();
    Hive.init('${cacheDirectory.path}/${HiveCacheManager.cacheSubDirectory}');
    await LocalSnapshotStore.instance.init();
  } catch (e) {
    debugPrint('[BackgroundChatAction] Hive init failed: $e');
  }
}

Future<bool> _tryAcquireActionLock(String key) async {
  final prefs = await SharedPreferences.getInstance();
  final existing = prefs.getInt(key);
  final now = DateTime.now().millisecondsSinceEpoch;
  if (existing != null && now - existing < 8000) return false;
  await prefs.setInt(key, now);
  return true;
}

Future<void> handleBackgroundChatAction(NotificationResponse response) async {
  final entryTime = DateTime.now();
  debugPrint(
    '[BackgroundChatAction] ENTRY actionId=${response.actionId} at=$entryTime',
  );

  final payload = response.payload;
  if (payload == null) return;

  final isGroup = payload.startsWith('group|');
  final parts = payload.split('|');
  if (parts.length < 4) return;

  final conversationId = isGroup ? parts[1] : parts[0];
  final conversationTitle = isGroup ? parts[2] : parts[1];
  final latestMessageId = parts[3];

  final lockKey = 'action_lock_${response.actionId}_$conversationId';
  if (!await _tryAcquireActionLock(lockKey)) {
    debugPrint('[BackgroundChatAction] duplicate ${response.actionId} ignored');
    return;
  }

  try {
    WidgetsFlutterBinding.ensureInitialized();

    await _ensureFirebaseReady();

    await NotificationPluginBootstrap.ensureInitialized(
      onForegroundTap: (r) {
        final actionId = r.actionId;
        if (actionId == 'reply_action' ||
            actionId == 'mark_read_action' ||
            actionId == 'mute_action') {
          handleBackgroundChatAction(r);
        } else {
          TapActionHandler.handleTap(r);
        }
      },
      onBackgroundTap: onBgNotificationActionTapped,
    );

    if (response.actionId == 'mute_action' ||
        response.actionId == 'mark_read_action') {
      unawaited(
        ChatNotificationDispatcher.instance.stripActionsInstantly(
          conversationId,
          conversationTitle,
        ),
      );
    }

    await Future.wait([_ensureHiveReady(), ensureSupabaseReady()]);

    final currentUserId = await _resolveCurrentUserId();
    if (currentUserId == null) {
      debugPrint(
        '[BackgroundChatAction] no restored session after '
        '${DateTime.now().difference(entryTime).inMilliseconds}ms — aborting',
      );
      await ChatNotificationDispatcher.instance.cancelNotificationSilently(
        conversationId,
      );
      return;
    }

    switch (response.actionId) {
      case 'mark_read_action':
        await ChatNotificationDispatcher.instance.handleMarkAsReadAction(
          isGroup: isGroup,
          conversationId: conversationId,
          currentUserId: currentUserId,
        );
        break;
      case 'mute_action':
        await ChatNotificationDispatcher.instance.handleMuteAction(
          isGroup: isGroup,
          conversationId: conversationId,
          currentUserId: currentUserId,
        );
        break;
      case 'reply_action':
        await ChatNotificationDispatcher.instance.handleReplyAction(
          response: response,
          parts: parts,
          isGroup: isGroup,
          conversationId: conversationId,
          conversationTitle: conversationTitle,
          latestMessageId: latestMessageId,
          currentUserId: currentUserId,
        );
        break;
    }

    debugPrint(
      '[BackgroundChatAction] EXIT actionId=${response.actionId} '
      'elapsedMs=${DateTime.now().difference(entryTime).inMilliseconds}',
    );
  } catch (e, st) {
    debugPrint(
      '[BackgroundChatAction] UNCAUGHT ERROR after '
      '${DateTime.now().difference(entryTime).inMilliseconds}ms: $e\n$st',
    );
    await ChatNotificationDispatcher.instance.cancelNotificationSilently(
      conversationId,
    );
  }
}

Future<String?> _resolveCurrentUserId() async {
  for (var attempt = 0; attempt < 12; attempt++) {
    try {
      final id = Supabase.instance.client.auth.currentUser?.id;
      if (id != null) return id;
    } catch (e) {
      debugPrint(
        '[BackgroundChatAction] Supabase not ready (attempt $attempt): $e',
      );
    }
    await Future.delayed(const Duration(milliseconds: 250));
  }
  return null;
}
