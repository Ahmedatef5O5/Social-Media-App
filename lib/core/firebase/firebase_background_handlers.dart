import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:social_media_app/firebase_options.dart';
import '../../features/settings/repository/settings_repository.dart';
import '../cache/services/hive_cache_manager.dart';
import '../cache/services/local_snapshot_store.dart';
import '../notifications/dispatchers/group_call_dispatcher.dart';
import '../notifications/notification_service.dart';
import '../services/incoming_call_navigation_guard.dart';
import '../supabase/supabase_provider.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();

  final type = message.data['notificationType'] as String? ?? 'chat';
  final isIncomingCall = type == 'incoming_call' || type == 'call';
  final isIncomingGroupCall =
      type == 'incoming_group_call' || type == 'group_call';

  // ── "Call Notifications" setting ─────────────────────────────────────────

  if (isIncomingCall || isIncomingGroupCall) {
    await SettingsRepository.instance.init();
    await SettingsRepository.instance.reload();
    if (!SettingsRepository.instance.callNotifications) return;

    // Already in another call: never ring on top of it. The main isolate
    // mirrors its busy state to disk for exactly this check.
    final incomingCallId =
        (message.data['callId'] ?? message.data['call_id']) as String? ?? '';
    if (await IncomingCallNavigationGuard.isUserBusyAcrossIsolates(
      incomingCallId,
    )) {
      return;
    }
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await NotificationService.instance.initialize(isBackground: true);

  if (isIncomingCall) {
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

  if (isIncomingGroupCall) {
    final callerId =
        (message.data['callerId'] ??
                message.data['initiatorId'] ??
                message.data['initiator_id'] ??
                '')
            as String;

    if (callerId.isNotEmpty && callerId == SupabaseProvider.idOrNull) {
      return;
    }

    // A delayed push for a call that already finished must not ring.
    final callId = message.data['callId'] as String? ?? '';
    if (callId.isNotEmpty) {
      try {
        final row =
            await SupabaseProvider.client
                .from('group_calls')
                .select('status')
                .eq('call_id', callId)
                .maybeSingle();
        final status = row?['status'] as String? ?? '';
        if (status == 'ended' || status == 'missed') return;
      } catch (e) {
        // Fail open: ringing for a finished call is better than missing a
        // real one.
        debugPrint('[BgHandler] group call status lookup failed: $e');
      }
    }

    await GroupCallDispatcher.instance.showIncomingGroupCallNotification(
      callId: callId,
      groupId: message.data['groupId'] ?? '',
      groupName: message.data['groupName'] ?? 'Group',
      groupAvatarUrl: message.data['groupAvatarUrl'] ?? '',
      callerName: message.data['callerName'] ?? 'Unknown',
      callType: message.data['callType'] ?? 'audio',
      callerId: callerId,
      startedAt: message.data['startedAt'] ?? '',
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
