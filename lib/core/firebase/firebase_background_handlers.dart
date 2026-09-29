import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:social_media_app/firebase_options.dart';
import '../cache/services/hive_cache_manager.dart';
import '../cache/services/local_snapshot_store.dart';
import '../notifications/dispatchers/group_call_dispatcher.dart';
import '../notifications/notification_service.dart';
import '../supabase/supabase_provider.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final type = message.data['notificationType'] as String? ?? 'chat';

  await NotificationService.instance.initialize(isBackground: true);

  if (type == 'incoming_call') {
    await NotificationService.instance.showIncomingCallNotification(
      callId: message.data['callId'] ?? '',
      callerId: message.data['callerId'] ?? '',
      callerName: message.data['callerName'] ?? 'Unknown',
      callerAvatar: message.data['callerAvatar'] ?? '',
      callType: message.data['callType'] ?? 'audio',
    );
    return;
  }

  if (type == 'call_cancelled') {
    final callId = message.data['callId'] as String?;
    if (callId != null && callId.isNotEmpty) {
      await NotificationService.instance.cancelCallNotification(callId);
    }
    return;
  }

  if (type == 'group_call_cancelled') {
    final callId = message.data['callId'] as String?;
    if (callId != null && callId.isNotEmpty) {
      await GroupCallDispatcher.instance.cancelIncomingGroupCallNotification(
        callId,
      );
    }
    return;
  }

  final cacheDirectory = await getApplicationDocumentsDirectory();
  Hive.init('${cacheDirectory.path}/${HiveCacheManager.cacheSubDirectory}');
  await LocalSnapshotStore.instance.init();

  await ensureSupabaseReady();

  if (type == 'incoming_group_call') {
    final callerId =
        (message.data['callerId'] ??
                message.data['initiatorId'] ??
                message.data['initiator_id'] ??
                '')
            as String;

    if (callerId.isNotEmpty && callerId == SupabaseProvider.idOrNull) {
      return;
    }

    await GroupCallDispatcher.instance.showIncomingGroupCallNotification(
      callId: message.data['callId'] ?? '',
      groupId: message.data['groupId'] ?? '',
      groupName: message.data['groupName'] ?? 'Group',
      groupAvatarUrl: message.data['groupAvatarUrl'] ?? '',
      callerName: message.data['callerName'] ?? 'Unknown',
      callType: message.data['callType'] ?? 'audio',
      callerId: callerId,
    );
    return;
  }

  if (NotificationService.isSocialType(type)) {
    await NotificationService.instance.showSocialNotificationFromMessage(
      message,
    );
    return;
  }

  await NotificationService.instance.showNotificationFromMessage(message);
}
