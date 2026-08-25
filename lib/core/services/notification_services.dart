import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/core/services/active_screen_tracker.dart';
import 'package:social_media_app/core/toast/app_toast.dart';
import 'package:social_media_app/features/single_chats/models/chat_user_model.dart';
import 'package:social_media_app/features/stories/cubit/stories_cubit/stories_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/group_calls/models/group_call_model.dart';
import '../../features/group_calls/views/incoming_group_call_screen.dart';
import '../../features/group_chats/services/group_chat_services.dart';
import '../../features/notifications/models/app_notification_model.dart';
import '../../features/notifications/views/notification_view.dart';
import '../../features/posts/model/post_details_route_args.dart';
import '../../features/posts/services/posts_services.dart';
import '../../features/posts/views/post_details_view.dart';
import '../../features/settings/repository/settings_repository.dart';
import '../../features/single_chats/services/chat_services.dart';
import '../../features/stories/model/story_model.dart';
import '../cache/services/hive_cache_manager.dart';
import '../cache/services/local_snapshot_store.dart';
import '../helpers/chat_helper.dart';
import '../secrets/app_secrets.dart';
import '../supabase/supabase_provider.dart';
import '../utilities/supabase_constants.dart';
import 'incoming_call_navigation_guard.dart';
import 'notification_avatar_builder.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:social_media_app/firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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

class _StoredMessage {
  final String text;
  final String senderName;
  final int timestamp;

  const _StoredMessage({
    required this.text,
    required this.senderName,
    required this.timestamp,
  });
}

// ============================================================================
// TOP-LEVEL BACKGROUND FUNCTIONS (Must be outside any class)
// ============================================================================

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
    NotificationService._handleTap(response);
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

    await NotificationService.instance.initialize(isBackground: true);

    if (response.actionId == 'mute_action' ||
        response.actionId == 'mark_read_action') {
      unawaited(
        NotificationService.instance._stripActionsInstantly(
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
      await NotificationService.instance._localNotifications.cancel(
        NotificationService.createUniqueId(conversationId),
      );
      return;
    }

    switch (response.actionId) {
      case 'mark_read_action':
        await _handleMarkAsRead(
          isGroup: isGroup,
          conversationId: conversationId,
          currentUserId: currentUserId,
        );
        break;
      case 'mute_action':
        await _handleMute(
          isGroup: isGroup,
          conversationId: conversationId,
          currentUserId: currentUserId,
        );
        break;
      case 'reply_action':
        await _handleReply(
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
    await NotificationService.instance._localNotifications.cancel(
      NotificationService.createUniqueId(conversationId),
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

Future<void> _handleMarkAsRead({
  required bool isGroup,
  required String conversationId,
  required String currentUserId,
}) async {
  try {
    if (isGroup) {
      await GroupChatServices().markGroupMessagesRead(conversationId);
    } else {
      await Supabase.instance.client
          .from('messages')
          .update({'is_read': true})
          .eq('sender_id', conversationId)
          .eq('receiver_id', currentUserId)
          .eq('is_read', false);
    }
    debugPrint(
      '[BackgroundChatAction] mark_read_action → DB write OK (isGroup=$isGroup)',
    );
  } catch (e) {
    debugPrint('[BackgroundChatAction] mark_read_action → DB write FAILED: $e');
  } finally {
    await NotificationService.instance.cancelNotificationsForSender(
      conversationId,
    );
  }
}

Future<void> _handleMute({
  required bool isGroup,
  required String conversationId,
  required String currentUserId,
}) async {
  try {
    if (isGroup) {
      await Supabase.instance.client
          .from('group_members')
          .update({'is_muted': true})
          .eq('group_id', conversationId)
          .eq('user_id', currentUserId);
    } else {
      await Supabase.instance.client.from('chat_mutes').upsert({
        'owner_id': currentUserId,
        'peer_id': conversationId,
        'is_muted': true,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    }
    debugPrint(
      '[BackgroundChatAction] mute_action → DB write OK (isGroup=$isGroup)',
    );
  } catch (e) {
    debugPrint('[BackgroundChatAction] mute_action → DB write FAILED: $e');
  } finally {
    await NotificationService.instance.cancelNotificationsForSender(
      conversationId,
    );
  }
}

Future<void> _handleReply({
  required NotificationResponse response,
  required List<String> parts,
  required bool isGroup,
  required String conversationId,
  required String conversationTitle,
  required String latestMessageId,
  required String currentUserId,
}) async {
  final replyText = response.input?.trim();
  if (replyText == null || replyText.isEmpty) {
    await NotificationService.instance._localNotifications.cancel(
      NotificationService.createUniqueId(conversationId),
    );
    return;
  }

  final avatarUrl =
      isGroup
          ? (parts.length > 4 && parts[4].isNotEmpty ? parts[4] : null)
          : (parts.length > 2 ? parts[2] : null);

  try {
    final String newMessageId;

    final userFuture =
        Supabase.instance.client
            .from('users')
            .select('image_url')
            .eq('id', currentUserId)
            .maybeSingle();
    if (isGroup) {
      final result = await GroupChatServices().sendGroupMessage(
        groupId: conversationId,
        groupName: conversationTitle,
        text: replyText,
      );
      newMessageId = result.id;
    } else {
      newMessageId = await ChatServices().sendMessage(
        senderId: currentUserId,
        receiverId: conversationId,
        text: replyText,
        replyToMessageId: latestMessageId.isEmpty ? null : latestMessageId,
      );
    }

    final userData = await userFuture;
    final myAvatarUrl = userData?['image_url'] as String?;

    await NotificationService.instance._updateNotificationAfterReply(
      conversationId: conversationId,
      isGroup: isGroup,
      conversationTitle: conversationTitle,
      replyText: replyText,
      avatarUrl: avatarUrl,
      newMessageId: newMessageId,
      myAvatarUrl: myAvatarUrl,
    );
  } catch (e, st) {
    debugPrint('[BackgroundChatAction] reply_action → send FAILED: $e\n$st');
    await NotificationService.instance._localNotifications.cancel(
      NotificationService.createUniqueId(conversationId),
    );
  }
}

// ============================================================================
// MAIN SERVICE CLASS
// ============================================================================

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final NotificationAvatarBuilder _avatarBuilder = NotificationAvatarBuilder();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  bool _initialized = false;

  static const Set<String> _socialNotificationTypes = {
    'friend_request',
    'friend_accept',
    'follow',
    'post_react',
    'post_comment',
    'post_reshare',
    'post_save',
    'mention',
    'comment_reply',
    'comment_react',
    'story_react',
    'message_react',
  };

  static int createUniqueId(String input) {
    int hash = 0;
    for (int i = 0; i < input.length; i++) {
      hash = 31 * hash + input.codeUnitAt(i);
    }
    return hash & 0x7FFFFFFF;
  }

  static bool isSocialType(String type) =>
      _socialNotificationTypes.contains(type);

  static final AndroidNotificationChannel _messageChannel =
      AndroidNotificationChannel(
        'chat_messages_channel',
        'Chat Messages',
        importance: Importance.high,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('message_tone'),
        enableVibration: true,
      );

  static final AndroidNotificationChannel _callChannel =
      AndroidNotificationChannel(
        'incoming_call_channel_v2',
        'Incoming Calls',
        description: 'Incoming call alerts',
        importance: Importance.max,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('incoming_ring'),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      );

  static final AndroidNotificationChannel
  _socialChannel = AndroidNotificationChannel(
    'social_events_channel',
    'Social & Post Activity',
    description:
        'Friend requests, follows, reactions, comments, mentions, shares, saves and story reactions',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  Future<void> initialize({bool isBackground = false}) async {
    if (_initialized) return;
    _initialized = true;

    const androidInit = AndroidInitializationSettings(
      '@drawable/ic_notification',
    );
    const initSettings = InitializationSettings(android: androidInit);

    // HERE IS THE FIX: Passing the top-level function directly.
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: onBgNotificationActionTapped,
    );

    final androidPlugin =
        _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    await androidPlugin?.createNotificationChannel(_messageChannel);
    await androidPlugin?.createNotificationChannel(_callChannel);
    await androidPlugin?.createNotificationChannel(_socialChannel);

    if (!isBackground) {
      await _requestPermissions();
      _listenToForegroundMessages();
      _listenToNotificationOpenedApp();
      _handleTerminatedAppLaunch();
    }
  }

  Future<void> cancelNotificationsForSender(String senderId) async {
    await _localNotifications.cancel(createUniqueId(senderId));
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('notif_style_history_$senderId');
    unawaited(
      LocalSnapshotStore.instance.clear('notif_style_history_$senderId'),
    );
  }

  Future<void> cancelCallNotification(String callId) async {
    await _localNotifications.cancel(createUniqueId(callId));
  }

  Future<void> _stripActionsInstantly(
    String conversationId,
    String title,
  ) async {
    try {
      await _localNotifications.show(
        createUniqueId(conversationId),
        title,
        'Updating...',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'chat_messages_channel',
            'Chat Messages',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@drawable/ic_notification',
            onlyAlertOnce: true,
            actions: [],
          ),
        ),
      );
    } catch (e) {
      debugPrint('[BackgroundChatAction] strip actions failed: $e');
    }
  }

  Future<void> _requestPermissions() async {
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
    );
  }

  void _listenToForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final type = message.data['notificationType'] as String? ?? 'chat';

      if (type == 'incoming_group_call') {
        if (!SettingsRepository.instance.callNotifications) return;
        await _handleIncomingGroupCallData(message.data);
        return;
      }

      if (type == 'incoming_call') {
        if (!SettingsRepository.instance.callNotifications) return;
        await _handleIncomingCallData(message.data);
        return;
      }

      if (!SettingsRepository.instance.pushNotifications) return;

      if (type == 'chat') {
        final senderId = message.data['senderId'] as String?;
        if (senderId != null &&
            !ActiveScreenTracker.isViewingChatWith(senderId)) {
          await showNotificationFromMessage(message);
        }
        return;
      }

      if (type == 'group_message') {
        final groupId = message.data['groupId'] as String?;
        if (groupId != null && !ActiveScreenTracker.isViewingGroup(groupId)) {
          await showNotificationFromMessage(message);
        }
        return;
      }

      if (type == 'message_react') {
        final isGroup = message.data['isGroup'] == 'true';

        if (isGroup) {
          final groupId = message.data['groupId'] as String?;
          if (groupId != null && ActiveScreenTracker.isViewingGroup(groupId)) {
            return;
          }
        } else {
          final actorId = message.data['actorId'] as String?;
          if (actorId != null &&
              ActiveScreenTracker.isViewingChatWith(actorId)) {
            return;
          }
        }
      }

      if (isSocialType(type)) {
        await showSocialNotificationFromMessage(message);
        return;
      }

      await showNotificationFromMessage(message);
    });
  }

  void _listenToNotificationOpenedApp() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final type = message.data['notificationType'] as String? ?? 'chat';
      if (type == 'incoming_call') {
        _handleIncomingCallData(message.data);
      } else if (type == 'incoming_group_call') {
        _handleIncomingGroupCallData(message.data);
      } else {
        _navigateFromMessage(message.data);
      }
    });
  }

  Future<void> _handleTerminatedAppLaunch() async {
    final message = await _fcm.getInitialMessage();
    if (message != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final type = message.data['notificationType'] as String? ?? 'chat';
        if (type == 'incoming_call') {
          _handleIncomingCallData(message.data);
        } else if (type == 'incoming_group_call') {
          _handleIncomingGroupCallData(message.data);
        } else {
          _navigateFromMessage(message.data);
        }
      });
    }
  }

  Future<void> showIncomingCallNotification({
    required String callId,
    required String callerId,
    required String callerName,
    required String callerAvatar,
    required String callType,
  }) async {
    Uint8List profileBitmap;
    try {
      profileBitmap = await _avatarBuilder.getAvatarBitmap(callerAvatar);
    } catch (_) {
      profileBitmap = await _avatarBuilder.defaultBitmap();
    }

    final subtitle =
        callType == 'video' ? 'Incoming video call' : 'Incoming voice call';

    final androidDetails = AndroidNotificationDetails(
      _callChannel.id,
      _callChannel.name,
      channelDescription: _callChannel.description,
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.call,
      icon: '@drawable/ic_notification',
      largeIcon: ByteArrayAndroidBitmap(profileBitmap),
      fullScreenIntent: true,
      ongoing: true,
      autoCancel: false,
      timeoutAfter: 60000,
      actions: [
        const AndroidNotificationAction(
          'decline_call',
          'Decline',
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'accept_call',
          'Accept',
          cancelNotification: true,
          showsUserInterface: true,
        ),
      ],
    );

    await _localNotifications.show(
      createUniqueId(callId),
      callerName,
      subtitle,
      NotificationDetails(android: androidDetails),
      payload: 'call|$callId|$callerId|$callerName|$callerAvatar|$callType',
    );
  }

  bool get _isAppInForeground =>
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  Future<void> _handleIncomingCallData(Map<String, dynamic> data) async {
    final callId = data['callId'] as String? ?? '';
    final callerId = (data['callerId'] ?? data['initiatorId'] ?? data['initiator_id'] ?? data['senderId']) as String? ?? '';
    final callerName = data['callerName'] as String? ?? 'Unknown';
    final callerAvatar = data['callerAvatar'] as String? ?? '';
    final callType = data['callType'] as String? ?? 'audio';

    if (callerId.isNotEmpty && callerId == SupabaseProvider.idOrNull) return;

    if (!_isAppInForeground) {
      await showIncomingCallNotification(
        callId: callId,
        callerId: callerId,
        callerName: callerName,
        callerAvatar: callerAvatar,
        callType: callType,
      );
    }

    if (!IncomingCallNavigationGuard.claim(callId)) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState
          ?.pushNamed(
            AppRoutes.incomingCallRoute,
            arguments: {
              'callId': callId,
              'callerId': callerId,
              'callerName': callerName,
              'callerAvatar': callerAvatar,
              'callType': callType,
            },
          )
          .then((_) => IncomingCallNavigationGuard.release(callId));
    });
  }

  Future<void> showIncomingGroupCallNotification({
    required String callId,
    required String groupId,
    required String groupName,
    required String groupAvatarUrl,
    required String callerName,
    required String callType,
  }) async {
    Uint8List profileBitmap;
    try {
      profileBitmap =
          await _avatarBuilder.fetchBitmap(groupAvatarUrl) ??
          await _avatarBuilder.buildLetterAvatar(groupName);
    } catch (_) {
      profileBitmap = await _avatarBuilder.defaultBitmap();
    }

    final subtitle =
        '$callerName is calling · ${callType == 'video' ? 'Group Video' : 'Group Voice'}';

    final androidDetails = AndroidNotificationDetails(
      _callChannel.id,
      _callChannel.name,
      channelDescription: _callChannel.description,
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.call,
      icon: '@drawable/ic_notification',
      largeIcon: ByteArrayAndroidBitmap(profileBitmap),
      fullScreenIntent: true,
      ongoing: true,
      autoCancel: false,
      timeoutAfter: 60000,
    );

    await _localNotifications.show(
      createUniqueId(callId),
      groupName,
      subtitle,
      NotificationDetails(android: androidDetails),
      payload:
          'group_call|$callId|$groupId|$groupName|$groupAvatarUrl|$callType',
    );
  }

  Future<void> _handleIncomingGroupCallData(Map<String, dynamic> data) async {
    final callerId = (data['callerId'] ?? data['initiatorId'] ?? data['initiator_id'] ?? data['senderId']) as String? ?? '';
    if (callerId == SupabaseProvider.idOrNull) return;
    final callId = (data['callId'] ?? data['call_id']) as String? ?? '';
    final groupId = data['groupId'] as String? ?? '';
    final groupName = data['groupName'] as String? ?? 'Group';
    final groupAvatarUrl = data['groupAvatarUrl'] as String?;
    final callerName = data['callerName'] as String? ?? 'Unknown';
    final callType = data['callType'] as String? ?? 'audio';
    final startedAt = data['startedAt'] as String?;

    if (!_isAppInForeground) {
      await showIncomingGroupCallNotification(
        callId: callId,
        groupId: groupId,
        groupName: groupName,
        groupAvatarUrl: groupAvatarUrl ?? '',
        callerName: callerName,
        callType: callType,
      );
    }

    final call = GroupCallModel(
      callId: callId,
      groupId: groupId,
      groupName: groupName,
      groupAvatarUrl: groupAvatarUrl,
      initiatorId: callerId,
      initiatorName: callerName,
      status: GroupCallStatus.ringing,
      type: callType == 'video' ? GroupCallType.video : GroupCallType.audio,
      startedAt:
          startedAt != null
              ? (DateTime.tryParse(startedAt) ?? DateTime.now())
              : DateTime.now(),
    );

    if (!IncomingCallNavigationGuard.claim(callId)) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState
          ?.push(
            MaterialPageRoute(
              builder: (_) => IncomingGroupCallScreen(call: call),
            ),
          )
          .then((_) => IncomingCallNavigationGuard.release(callId));
    });
  }

  Future<void> showNotificationFromMessage(RemoteMessage message) async {
    final data = message.data;
    final notification = message.notification;

    final String type = data['notificationType'] ?? 'chat';
    final bool isGroup = type == 'group_message';

    await _hydrateMessageCache(data, isGroup);

    final String conversationId =
        isGroup ? (data['groupId'] ?? '') : (data['senderId'] ?? '');

    final String senderName =
        data['senderName'] ?? notification?.title ?? 'New Message';

    final String conversationTitle =
        isGroup ? (data['groupName'] ?? 'Group') : senderName;
    final bool isForwarded = data['is_forwarded'] == 'true';

    final String rawBody =
        SettingsRepository.instance.messagePreviews
            ? _buildStyleBody(
              data['messageType'] ?? 'text',
              data['messageBody'] ?? notification?.body ?? '',
            )
            : 'New message';

    final String body = isForwarded ? '↪️ Forwarded: $rawBody' : rawBody;
    final String? avatarUrl = data['senderImageUrl'];

    Future<Uint8List> getGroupAvatarBitmap(
      String groupName,
      String? groupImageUrl,
    ) async {
      if (groupImageUrl != null && groupImageUrl.isNotEmpty) {
        final bytes = await _avatarBuilder.fetchBitmap(groupImageUrl);
        if (bytes != null) return bytes;
      }

      return await _avatarBuilder.buildLetterAvatar(groupName);
    }

    final stored = await _appendToMessageHistory(
      conversationId,
      _StoredMessage(
        text: body,
        senderName: senderName,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );

    final Uint8List senderBitmap = await _avatarBuilder.getAvatarBitmap(
      avatarUrl,
    );
    final Uint8List headerBitmap =
        isGroup
            ? await getGroupAvatarBitmap(
              conversationTitle,
              data['groupImageUrl'],
            )
            : senderBitmap;

    final ByteArrayAndroidIcon headerIcon = ByteArrayAndroidIcon(headerBitmap);
    final ByteArrayAndroidIcon senderIcon = ByteArrayAndroidIcon(senderBitmap);

    const Person me = Person(name: 'Me', important: true);

    final Person remotePerson =
        isGroup
            ? Person(name: conversationTitle, icon: headerIcon)
            : Person(name: senderName, icon: senderIcon);

    final List<Message> styleMessages =
        stored
            .map(
              (m) => Message(
                isGroup ? '${m.senderName}: ${m.text}' : m.text,
                DateTime.fromMillisecondsSinceEpoch(m.timestamp),
                remotePerson,
              ),
            )
            .toList();

    final messagingStyle = MessagingStyleInformation(
      me,
      conversationTitle: isGroup ? conversationTitle : null,
      groupConversation: isGroup,
      messages: styleMessages,
    );

    final androidDetails = AndroidNotificationDetails(
      _messageChannel.id,
      _messageChannel.name,
      channelDescription: _messageChannel.description,
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.message,
      icon: '@drawable/ic_notification',
      largeIcon: ByteArrayAndroidBitmap(headerBitmap),
      styleInformation: messagingStyle,
      autoCancel: true,
      ongoing: false,
      color: const Color(0xFF2196F3),
      actions: [
        const AndroidNotificationAction(
          'mute_action',
          'Mute',
          showsUserInterface: false,
          cancelNotification: true,
        ),

        // if (!isGroup)
        const AndroidNotificationAction(
          'mark_read_action',
          'Mark as Read',
          showsUserInterface: false,
          cancelNotification: true,
        ),

        AndroidNotificationAction(
          'reply_action',
          'Reply',
          inputs: const [
            AndroidNotificationActionInput(label: 'Type a message...'),
          ],
          showsUserInterface: false,
          cancelNotification: false,
          allowGeneratedReplies: false,
        ),
      ],
    );

    final String? latestMessageId = data['messageId'] as String?;
    final String? groupImageUrl = data['groupImageUrl'] as String?;

    await _localNotifications.show(
      createUniqueId(conversationId),
      conversationTitle,
      body,
      NotificationDetails(android: androidDetails),

      payload:
          isGroup
              ? 'group|$conversationId|$conversationTitle|${latestMessageId ?? ''}|${groupImageUrl ?? ''}'
              : '$conversationId|$senderName|${avatarUrl ?? ''}|${latestMessageId ?? ''}',
    );
  }

  Future<List<_StoredMessage>> _appendToMessageHistory(
    String conversationId,
    _StoredMessage message,
  ) async {
    final key = 'notif_style_history_$conversationId';

    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    final rawString = prefs.getString(key);
    List<dynamic> raw = [];
    if (rawString != null) {
      try {
        raw = jsonDecode(rawString) as List<dynamic>;
      } catch (_) {}
    }

    final history =
        raw
            .map(
              (m) => _StoredMessage(
                text: m['text'] as String? ?? '',
                senderName: m['senderName'] as String? ?? '',
                timestamp:
                    (m['timestamp'] as num?)?.toInt() ??
                    DateTime.now().millisecondsSinceEpoch,
              ),
            )
            .toList();

    history.add(message);

    if (history.length > 7) history.removeAt(0);

    await prefs.setString(
      key,
      jsonEncode(
        history
            .map(
              (m) => {
                'text': m.text,
                'senderName': m.senderName,
                'timestamp': m.timestamp,
              },
            )
            .toList(),
      ),
    );

    return history;
  }

  Future<void> _hydrateMessageCache(
    Map<String, dynamic> data,
    bool isGroup,
  ) async {
    try {
      final String type = data['notificationType'] ?? 'chat';
      if (type != 'chat' && type != 'group_message') return;

      final String? messageId = data['messageId'] as String?;
      if (messageId == null || messageId.isEmpty) return;

      final String messageType = data['messageType'] ?? 'text';
      final String? attachmentUrl = _s(data['attachmentUrl']);
      final String createdAt = DateTime.now().toIso8601String();

      final String key;
      final Map<String, dynamic> shadowMessage;

      if (isGroup) {
        final String groupId = data['groupId'] ?? '';
        if (groupId.isEmpty) return;
        key = 'group_messages_snapshot_$groupId';

        shadowMessage = {
          'id': messageId,
          GroupMemberColumns.groupId: groupId,
          'sender_id': data['senderId'] ?? '',
          'sender_name': data['senderName'] ?? 'Unknown',
          'sender_avatar': _s(data['senderImageUrl']),
          'message_text': data['messageBody'] ?? '',
          'created_at': createdAt,
          'message_type': messageType,
          'image_url': messageType == 'image' ? attachmentUrl : null,
          'video_url': messageType == 'video' ? attachmentUrl : null,
          'voice_url': messageType == 'voice' ? attachmentUrl : null,
          MessagesColumns.durationSeconds: int.tryParse(
            data['durationSeconds'] ?? '',
          ),
          'file_url': messageType == 'file' ? attachmentUrl : null,
          MessagesColumns.fileName: _s(data['fileName']),
          MessagesColumns.fileSizeBytes: int.tryParse(
            data['fileSizeBytes'] ?? '',
          ),
          MessagesColumns.caption: _s(data['caption']),
          'reply_to_message_id': _s(data['replyToMessageId']),
          'reply_to_text': _s(data['replyToText']),
          'reply_to_sender_id': _s(data['replyToSenderId']),
          'reply_to_sender_name': null,
          'reply_to_message_type': _s(data['replyToMessageType']),
          'reply_to_media_url': _s(data['replyToMediaUrl']),
          'forwarded_from_user_id': _s(data['forwardedFromUserId']),
          'forwarded_from_user_name': _s(data['forwardedFromUserName']),
          'forwarded_from_user_avatar': _s(data['forwardedFromUserAvatar']),
          'mentions': const [],
          'reactions': const {},
          'reactionsCreatedAt': const {},
          'read_by': const [],
          'is_edited': false,
          'deleted_for': const [],
          'system_event_data': null,
          'target_id': null,
          'target_name': null,
        };
      } else {
        final String? senderId = data['senderId'] as String?;
        final String? currentUserId =
            Supabase.instance.client.auth.currentUser?.id;
        if (senderId == null || senderId.isEmpty || currentUserId == null) {
          return;
        }
        final conversationId = ChatHelper.buildConversationId(
          currentUserId,
          senderId,
        );
        key = 'chat_messages_snapshot_$conversationId';

        shadowMessage = {
          MessagesColumns.id: messageId,
          MessagesColumns.senderId: senderId,
          MessagesColumns.receiverId: currentUserId,
          MessagesColumns.messageText: data['messageBody'] ?? '',
          MessagesColumns.createdAt: createdAt,
          MessagesColumns.isRead: false,
          MessagesColumns.isEdited: false,
          MessagesColumns.messageType: messageType,
          MessagesColumns.imageUrl:
              messageType == 'image' ? attachmentUrl : null,
          MessagesColumns.videoUrl:
              messageType == 'video' ? attachmentUrl : null,
          MessagesColumns.voiceUrl:
              messageType == 'voice' ? attachmentUrl : null,
          MessagesColumns.durationSeconds: int.tryParse(
            data['durationSeconds'] ?? '',
          ),
          MessagesColumns.fileName: _s(data['fileName']),
          MessagesColumns.fileSizeBytes: int.tryParse(
            data['fileSizeBytes'] ?? '',
          ),
          MessagesColumns.caption: _s(data['caption']),
          MessagesColumns.replyToMessageId: _s(data['replyToMessageId']),
          MessagesColumns.replyToText: _s(data['replyToText']),
          MessagesColumns.replyToMessageType: _s(data['replyToMessageType']),
          MessagesColumns.replyToSenderId: _s(data['replyToSenderId']),
          MessagesColumns.replyToMediaUrl: _s(data['replyToMediaUrl']),
          MessagesColumns.replyToStoryId: _s(data['replyToStoryId']),
          MessagesColumns.replyToStoryAuthorId: _s(
            data['replyToStoryAuthorId'],
          ),
          MessagesColumns.replyToStoryType: _s(data['replyToStoryType']),
          MessagesColumns.replyToStoryMediaUrl: _s(
            data['replyToStoryMediaUrl'],
          ),
          MessagesColumns.replyToStoryText: _s(data['replyToStoryText']),
          MessagesColumns.replyToStoryBgColor: _s(data['replyToStoryBgColor']),
          MessagesColumns.replyToStoryDurationSeconds: int.tryParse(
            data['replyToStoryDurationSeconds'] ?? '',
          ),
          MessagesColumns.forwardedFromUserId: _s(data['forwardedFromUserId']),
          MessagesColumns.forwardedFromUserName: _s(
            data['forwardedFromUserName'],
          ),
          MessagesColumns.forwardedFromUserAvatar: _s(
            data['forwardedFromUserAvatar'],
          ),
          'reactionsCreatedAt': const {},
          MessagesColumns.deletedFor: const <String>[],
        };
      }

      final existing = LocalSnapshotStore.instance.readList(key);
      if (existing.any((m) => m['id'] == messageId)) return;

      await LocalSnapshotStore.instance.saveList(key, [
        shadowMessage,
        ...existing,
      ]);
    } catch (e) {
      debugPrint('⚠️ _hydrateMessageCache silent error: $e');
    }
  }

  static String? _s(dynamic v) => (v == null || v == '') ? null : v as String;

  Future<void> showSocialNotificationFromMessage(RemoteMessage message) async {
    final data = message.data;
    final String type = data['notificationType'] ?? 'general';

    final String actorId =
        data['actorId'] ?? data['requesterId'] ?? data['followerId'] ?? '';
    final String actorName =
        data['actorName'] ??
        data['requesterName'] ??
        data['followerName'] ??
        'Someone';
    final String actorImageUrl =
        data['actorImageUrl'] ??
        data['requesterImageUrl'] ??
        data['followerImageUrl'] ??
        '';
    final String referenceId = _resolveReferenceId(data);

    final String title =
        (data['title'] as String?)?.isNotEmpty == true
            ? data['title']!
            : actorName;
    final String body =
        (data['body'] as String?)?.isNotEmpty == true
            ? data['body']!
            : 'New notification';

    Uint8List avatarBitmap;
    try {
      avatarBitmap = await _avatarBuilder.getAvatarBitmap(actorImageUrl);
    } catch (_) {
      avatarBitmap = await _avatarBuilder.defaultBitmap();
    }

    final androidDetails = AndroidNotificationDetails(
      _socialChannel.id,
      _socialChannel.name,
      channelDescription: _socialChannel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_notification',
      largeIcon: ByteArrayAndroidBitmap(avatarBitmap),
      styleInformation: BigTextStyleInformation(body),
      autoCancel: true,
      color: const Color(0xFF2196F3),
    );

    final String mentionContext = data['context'] ?? '';

    await _localNotifications.show(
      createUniqueId('$type|$referenceId|$actorId'),
      title,
      body,
      NotificationDetails(android: androidDetails),
      payload:
          type == 'message_react'
              ? 'message_react|${data['isGroup']}|${data['groupId']}|${data['groupName']}|${data['actorId']}|${data['actorName']}|${data['actorImageUrl']}'
              : 'social|$type|$referenceId|$actorId|$actorName|$actorImageUrl|$mentionContext',
    );
  }

  static String _resolveReferenceId(Map<String, dynamic> data) {
    final postId = data['postId'] as String?;
    if (postId != null && postId.isNotEmpty) return postId;
    final storyId = data['storyId'] as String?;
    if (storyId != null && storyId.isNotEmpty) return storyId;
    return '';
  }

  String _buildStyleBody(String type, String body) {
    switch (type) {
      case 'image':
        return '📷 Photo';
      case 'video':
        return '🎥 Video';
      case 'voice':
        return '🎤 Voice message';
      case 'gif':
        return '🖼️ GIF';
      case 'sticker':
        return '🏷️ Sticker';
      case 'file':
        return '📄 File';
      default:
        return body;
    }
  }

  @pragma('vm:entry-point')
  static void _onNotificationTapped(NotificationResponse response) async {
    final actionId = response.actionId;
    if (actionId == 'reply_action' ||
        actionId == 'mark_read_action' ||
        actionId == 'mute_action') {
      await handleBackgroundChatAction(response);
      return;
    }
    _handleTap(response);
  }

  Future<void> _updateNotificationAfterReply({
    required String conversationId,
    required bool isGroup,
    required String conversationTitle,
    required String replyText,
    required String? avatarUrl,
    required String newMessageId,
    String? myAvatarUrl,
  }) async {
    final stored = await _appendToMessageHistory(
      conversationId,
      _StoredMessage(
        text: replyText,
        senderName: 'You',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );

    final Uint8List senderBitmap = await _avatarBuilder.getAvatarBitmap(
      avatarUrl,
    );

    final Uint8List headerBitmap =
        isGroup
            ? ((avatarUrl != null && avatarUrl.isNotEmpty)
                ? (await _avatarBuilder.fetchBitmap(avatarUrl) ??
                    await _avatarBuilder.buildLetterAvatar(conversationTitle))
                : await _avatarBuilder.buildLetterAvatar(conversationTitle))
            : senderBitmap;

    final Uint8List myBitmap = await _avatarBuilder.getAvatarBitmap(
      myAvatarUrl,
    );

    final Person me = Person(
      name: 'You',
      important: true,
      icon: ByteArrayAndroidIcon(myBitmap),
    );

    final Person remotePerson = Person(
      name: conversationTitle,
      icon: ByteArrayAndroidIcon(headerBitmap),
    );

    final List<Message> styleMessages =
        stored.map((m) {
          final isMine = m.senderName == 'You';
          final text =
              (isGroup && !isMine) ? '${m.senderName}: ${m.text}' : m.text;
          return Message(
            text,
            DateTime.fromMillisecondsSinceEpoch(m.timestamp),
            isMine ? null : remotePerson,
          );
        }).toList();

    final messagingStyle = MessagingStyleInformation(
      me,
      conversationTitle: isGroup ? conversationTitle : null,
      groupConversation: isGroup,
      messages: styleMessages,
    );

    final androidDetails = AndroidNotificationDetails(
      _messageChannel.id,
      _messageChannel.name,
      channelDescription: _messageChannel.description,
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.message,
      icon: '@drawable/ic_notification',
      largeIcon: ByteArrayAndroidBitmap(headerBitmap),
      styleInformation: messagingStyle,
      autoCancel: true,
      ongoing: false,
      color: const Color(0xFF2196F3),
    );

    await _localNotifications.show(
      createUniqueId(conversationId),
      conversationTitle,
      replyText,
      NotificationDetails(android: androidDetails),
      // Keep the avatar threaded through so a *second* reply on the same
      // notification (before the user reopens the app) still has it.
      payload:
          isGroup
              ? 'group|$conversationId|$conversationTitle|$newMessageId|${avatarUrl ?? ''}'
              : '$conversationId|$conversationTitle|${avatarUrl ?? ''}|$newMessageId',
    );
  }

  static void _handleTap(NotificationResponse response) {
    if (response.payload == null) return;
    final payload = response.payload!;

    if (payload.startsWith('message_react|')) {
      final parts = payload.split('|');
      if (parts.length >= 7) {
        final isGroup = parts[1] == 'true';
        if (isGroup) {
          _openGroupChat(parts[2], parts[3]);
        } else {
          final user = ChatUserModel(
            id: parts[4],
            name: parts[5],
            imageUrl: parts[6].isEmpty ? null : parts[6],
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            navigatorKey.currentState?.pushNamed(
              AppRoutes.chatDetailsViewRoute,
              arguments: user,
            );
          });
        }
      }
      return;
    }

    if (payload.startsWith('group_call|')) {
      final parts = payload.split('|');
      if (parts.length >= 6) {
        final callId = parts[1];
        if (!IncomingCallNavigationGuard.claim(callId)) return;
        unawaited(instance.cancelCallNotification(callId));

        final call = GroupCallModel(
          callId: parts[1],
          groupId: parts[2],
          groupName: parts[3],
          groupAvatarUrl: parts[4],
          initiatorId: '',
          initiatorName: parts[3],
          status: GroupCallStatus.ringing,
          type: parts[5] == 'video' ? GroupCallType.video : GroupCallType.audio,
          startedAt: DateTime.now(),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigatorKey.currentState
              ?.push(
                MaterialPageRoute(
                  builder: (_) => IncomingGroupCallScreen(call: call),
                ),
              )
              .then((_) => IncomingCallNavigationGuard.release(callId));
        });
      }
      return;
    }

    if (payload.startsWith('call|')) {
      final parts = payload.split('|');
      if (parts.length >= 6) {
        final callId = parts[1];
        if (response.actionId == 'decline_call') {
          _rejectCallViaRest(callId);
          return;
        }
        if (!IncomingCallNavigationGuard.claim(callId)) return;
        unawaited(instance.cancelCallNotification(callId));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigatorKey.currentState
              ?.pushNamed(
                AppRoutes.incomingCallRoute,
                arguments: {
                  'callId': callId,
                  'callerId': parts[2],
                  'callerName': parts[3],
                  'callerAvatar': parts[4],
                  'callType': parts[5],
                },
              )
              .then((_) => IncomingCallNavigationGuard.release(callId));
        });
      }
      return;
    }

    if (payload.startsWith('group|')) {
      final parts = payload.split('|');
      if (parts.length >= 3) {
        _navigateFromMessage({
          'notificationType': 'group_message',
          'groupId': parts[1],
          'groupName': parts[2],
        });
      }
      return;
    }

    if (payload.startsWith('social|')) {
      final parts = payload.split('|');
      if (parts.length >= 2) {
        _routeSocialEvent(
          type: parts[1],
          referenceId: parts.length > 2 ? parts[2] : '',
          commentContext: parts.length > 6 ? parts[6] : null,
        );
      }
      return;
    }

    final parts = payload.split('|');
    if (parts.length >= 2) {
      _navigateFromMessage({
        'senderId': parts[0],
        'senderName': parts[1],
        'senderImageUrl': parts.length > 2 ? parts[2] : null,
      });
    }
  }

  static Future<void> _rejectCallViaRest(String callId) async {
    try {
      final dio = dio_pkg.Dio();
      const supabaseUrl = String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: '',
      );
      const anonKey = String.fromEnvironment(
        'SUPABASE_ANON_KEY',
        defaultValue: '',
      );

      if (supabaseUrl.isEmpty || anonKey.isEmpty) return;

      await dio.patch(
        '$supabaseUrl/rest/v1/calls?call_id=eq.$callId',
        data: {'status': 'rejected'},
        options: dio_pkg.Options(
          headers: {
            'apikey': anonKey,
            'Authorization': 'Bearer $anonKey',
            'Content-Type': 'application/json',
            'Prefer': 'return=minimal',
          },
        ),
      );
    } catch (e) {
      debugPrint('_rejectCallViaRest error: $e');
    }
  }

  static void _navigateFromMessage(Map<String, dynamic> data) {
    final notifType = data['notificationType'] as String? ?? 'chat';

    if (notifType == 'message_react') {
      final isGroup = data['isGroup'] == 'true';
      if (isGroup) {
        _openGroupChat(
          data['groupId'] as String? ?? '',
          data['groupName'] as String? ?? 'Group',
        );
      } else {
        final user = ChatUserModel(
          id: data['actorId'] ?? '',
          name: data['actorName'] ?? '',
          imageUrl: data['actorImageUrl'],
        );
        navigatorKey.currentState?.pushNamed(
          AppRoutes.chatDetailsViewRoute,
          arguments: user,
        );
      }
      return;
    }
    if (notifType == 'group_message') {
      _openGroupChat(
        data['groupId'] as String? ?? '',
        data['groupName'] as String? ?? 'Group',
      );
      return;
    }
    if (isSocialType(notifType)) {
      _routeSocialEvent(
        type: notifType,
        referenceId: _resolveReferenceId(data),
        commentContext: data['context'] as String?,
      );
      return;
    }

    final user = ChatUserModel(
      id: data['senderId'] ?? '',
      name: data['senderName'] ?? '',
      imageUrl: data['senderImageUrl'],
    );
    navigatorKey.currentState?.pushNamed(
      AppRoutes.chatDetailsViewRoute,
      arguments: user,
    );
  }

  static void _routeSocialEvent({
    required String type,
    required String referenceId,
    String? commentContext,
  }) {
    const postEngagementTypes = {
      'post_react',
      'post_comment',
      'post_reshare',
      'post_save',
      'comment_reply',
      'comment_react',
    };

    if (type == 'mention') {
      if (commentContext == 'story' && referenceId.isNotEmpty) {
        _openMentionedStory(referenceId);
      } else if (referenceId.isNotEmpty) {
        _openPostDetails(referenceId, PostDetailsActiveMode.comments);
      } else {
        _openNotificationsView();
      }
      return;
    }

    if (type == 'story_react' && referenceId.isNotEmpty) {
      _openMyStory(referenceId);
      return;
    }

    if (postEngagementTypes.contains(type) && referenceId.isNotEmpty) {
      _openPostDetails(referenceId, _activeModeForType(type));
      return;
    }
    if (type == 'friend_request') {
      _openNotificationsView(NotificationType.friendRequest);
      return;
    }

    if (type == 'follow') {
      _openNotificationsView(NotificationType.follow);
      return;
    }

    _openNotificationsView();
  }

  static PostDetailsActiveMode _activeModeForType(String type) {
    switch (type) {
      case 'post_react':
        return PostDetailsActiveMode.reactions;
      case 'post_comment':
      case 'comment_reply':
      case 'comment_react':
        return PostDetailsActiveMode.comments;
      case 'post_reshare':
      case 'post_save':
      default:
        return PostDetailsActiveMode.none;
    }
  }

  static Future<void> _openPostDetails(
    String postId, [
    PostDetailsActiveMode initialActiveMode = PostDetailsActiveMode.none,
  ]) async {
    final post = await PostsServices().fetchPostById(postId);
    if (post == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.homeRoute,
        (route) => false,
      );
      navigatorKey.currentState?.pushNamed(
        AppRoutes.postDetailsViewRoute,
        arguments: PostDetailsRouteArgs(
          post: post,
          initialActiveMode: initialActiveMode,
        ),
      );
    });
  }

  static void _openNotificationsView([NotificationType? initialFilter]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => NotificationsView(initialFilter: initialFilter),
        ),
      );
    });
  }

  static Future<void> _openMyStory(String storyId) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    final storiesCubit = context.read<StoriesCubit>();

    try {
      await storiesCubit.fetchStories(isRefresh: true);
      final myUserId = SupabaseProvider.idOrNull;
      final myStories =
          storiesCubit.cachedStories
              .where((s) => s.authorId == myUserId)
              .toList();
      final storyIndex = myStories.indexWhere((s) => s.id == storyId);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          AppRoutes.homeRoute,
          (route) => false,
        );

        navigatorKey.currentState?.pushNamed(
          AppRoutes.myStoriesListViewRoute,
          arguments: {'storiesCubit': storiesCubit, 'myStories': myStories},
        );

        if (storyIndex == -1) {
          AppToast.warning('This story is no longer available');
        } else {
          navigatorKey.currentState?.pushNamed(
            AppRoutes.storyDisplayViewRoute,
            arguments: {
              'storiesCubit': storiesCubit,
              'allUserGroups': [myStories],
              'initialGroupIndex': 0,
              'initialStoryIndex': storyIndex,
            },
          );
        }
      });
    } catch (e) {
      debugPrint('Error opening story from notification: $e');
      AppToast.error('Failed to open story');
    }
  }

  static Future<void> _openMentionedStory(String storyId) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    final storiesCubit = context.read<StoriesCubit>();

    try {
      await storiesCubit.fetchStories(isRefresh: true);
      final match = storiesCubit.cachedStories.where((s) => s.id == storyId);
      final authorId = match.isNotEmpty ? match.first.authorId : null;
      final authorGroup =
          authorId == null
              ? <StoryModel>[]
              : storiesCubit.cachedStories
                  .where((s) => s.authorId == authorId)
                  .toList();
      final storyIndex = authorGroup.indexWhere((s) => s.id == storyId);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          AppRoutes.homeRoute,
          (route) => false,
        );

        if (storyIndex == -1) {
          AppToast.warning('This story is no longer available');
          return;
        }

        navigatorKey.currentState?.pushNamed(
          AppRoutes.storyDisplayViewRoute,
          arguments: {
            'storiesCubit': storiesCubit,
            'allUserGroups': [authorGroup],
            'initialGroupIndex': 0,
            'initialStoryIndex': storyIndex,
          },
        );
      });
    } catch (e) {
      debugPrint('Error opening mentioned story from notification: $e');
      AppToast.error('Failed to open story');
    }
  }

  static Future<void> _openGroupChat(String groupId, String groupName) async {
    if (groupId.isEmpty) {
      _openNotificationsView();
      return;
    }
    try {
      final groups = await GroupChatServices().getMyGroups();
      final matches = groups.where((g) => g.id == groupId);
      final group = matches.isNotEmpty ? matches.first : null;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (group == null) {
          AppToast.warning('This group is no longer available');
          return;
        }
        navigatorKey.currentState?.pushNamed(
          AppRoutes.groupChatRoute,
          arguments: group,
        );
      });
    } catch (e) {
      debugPrint('Error opening group chat from notification: $e');
      AppToast.error('Failed to open group chat');
    }
  }
}
