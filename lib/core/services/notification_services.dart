import 'dart:typed_data';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/core/services/active_screen_tracker.dart';
import 'package:social_media_app/features/single_chats/models/chat_user_model.dart';
import '../../features/settings/repository/settings_repository.dart';
import 'notification_avatar_builder.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static final Map<String, List<_StoredMessage>> _messagesByConversation = {};

  final NotificationAvatarBuilder _avatarBuilder = NotificationAvatarBuilder();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  bool _initialized = false;

  static final AndroidNotificationChannel _messageChannel =
      AndroidNotificationChannel(
        'chat_messages_channel',
        'Chat Messages',
        description: 'New chat message notifications',
        importance: Importance.high,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('message_tone'),
        enableVibration: true,
      );

  static final AndroidNotificationChannel _callChannel =
      AndroidNotificationChannel(
        'incoming_call_channel',
        'Incoming Calls',
        description: 'Incoming call alerts',
        importance: Importance.max,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('incoming_ring'),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      );

  Future<void> initialize({bool isBackground = false}) async {
    if (_initialized) return;
    _initialized = true;

    const androidInit = AndroidInitializationSettings(
      '@drawable/ic_notification',
    );
    const initSettings = InitializationSettings(android: androidInit);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: _onBgNotificationTapped,
    );

    final androidPlugin =
        _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    await androidPlugin?.createNotificationChannel(_messageChannel);
    await androidPlugin?.createNotificationChannel(_callChannel);

    if (!isBackground) {
      await _requestPermissions();
      _listenToForegroundMessages();
      _listenToNotificationOpenedApp();
      _handleTerminatedAppLaunch();
    }
  }

  Future<void> cancelNotificationsForSender(String senderId) async {
    await _localNotifications.cancel(senderId.hashCode);
    _messagesByConversation.remove(senderId);
  }

  Future<void> cancelCallNotification(String callId) async {
    await _localNotifications.cancel(callId.hashCode);
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

      await showNotificationFromMessage(message);
    });
  }

  void _listenToNotificationOpenedApp() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final type = message.data['notificationType'] as String? ?? 'chat';
      if (type == 'incoming_call') {
        _handleIncomingCallData(message.data);
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
      profileBitmap = await _avatarBuilder.getAvatarBitmap(
        callerId,
        callerAvatar,
      );
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
      callId.hashCode,
      callerName,
      subtitle,
      NotificationDetails(android: androidDetails),
      payload: 'call|$callId|$callerId|$callerName|$callerAvatar|$callType',
    );
  }

  Future<void> _handleIncomingCallData(Map<String, dynamic> data) async {
    final callId = data['callId'] as String? ?? '';
    final callerId = data['callerId'] as String? ?? '';
    final callerName = data['callerName'] as String? ?? 'Unknown';
    final callerAvatar = data['callerAvatar'] as String? ?? '';
    final callType = data['callType'] as String? ?? 'audio';

    await showIncomingCallNotification(
      callId: callId,
      callerId: callerId,
      callerName: callerName,
      callerAvatar: callerAvatar,
      callType: callType,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.pushNamed(
        AppRoutes.incomingCallRoute,
        arguments: {
          'callId': callId,
          'callerId': callerId,
          'callerName': callerName,
          'callerAvatar': callerAvatar,
          'callType': callType,
        },
      );
    });
  }

  Future<void> showNotificationFromMessage(RemoteMessage message) async {
    final data = message.data;
    final notification = message.notification;

    final String type = data['notificationType'] ?? 'chat';
    final bool isGroup = type == 'group_message';

    final String conversationId =
        isGroup ? (data['groupId'] ?? '') : (data['senderId'] ?? '');

    final String senderName =
        data['senderName'] ?? notification?.title ?? 'New Message';

    final String conversationTitle =
        isGroup ? (data['groupName'] ?? 'Group') : senderName;

    final String body =
        SettingsRepository.instance.messagePreviews
            ? _buildStyleBody(
              data['messageType'] ?? 'text',
              data['messageBody'] ?? notification?.body ?? '',
            )
            : 'New message';

    final String? avatarUrl = data['senderImageUrl'];
    final String? groupImageUrl = data['groupImageUrl'];

    Future<Uint8List> _getGroupAvatarBitmap(
      String groupName,
      String? groupImageUrl,
    ) async {
      if (groupImageUrl != null && groupImageUrl.isNotEmpty) {
        final bytes = await _avatarBuilder.fetchBitmap(groupImageUrl);
        if (bytes != null) return bytes;
      }

      return await _avatarBuilder.buildLetterAvatar(groupName);
    }

    final stored = _messagesByConversation.putIfAbsent(
      conversationId,
      () => [],
    );
    stored.add(
      _StoredMessage(
        text: body,
        senderName: senderName,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    if (stored.length > 7) stored.removeAt(0);

    final Uint8List senderBitmap = await _avatarBuilder.getAvatarBitmap(
      conversationId,
      avatarUrl,
    );

    final Uint8List headerBitmap =
        isGroup
            ? await _getGroupAvatarBitmap(
              conversationTitle,
              data['groupImageUrl'],
            )
            : senderBitmap;

    final ByteArrayAndroidIcon headerIcon = ByteArrayAndroidIcon(headerBitmap);

    final ByteArrayAndroidIcon senderIcon = ByteArrayAndroidIcon(senderBitmap);

    // Profile bitmap is typically the sender's avatar, so we request it from the builder.
    // final Uint8List profileBitmap = await _avatarBuilder.getAvatarBitmap(conversationId, avatarUrl);

    final Person person = Person(
      name: conversationTitle,
      icon: headerIcon,
      important: true,
    );

    final List<Message> styleMessages =
        stored
            .map(
              (m) => Message(
                m.text,
                DateTime.fromMillisecondsSinceEpoch(m.timestamp),
                Person(name: m.senderName, icon: senderIcon),
              ),
            )
            .toList();

    final messagingStyle = MessagingStyleInformation(
      person,
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
      conversationId.hashCode,
      conversationTitle,
      body,
      NotificationDetails(android: androidDetails),
      payload:
          isGroup
              ? 'group|$conversationId|$conversationTitle'
              : '$conversationId|$senderName|$avatarUrl',
    );
  }

  String _buildStyleBody(String type, String body) {
    switch (type) {
      case 'image':
        return '📷 Photo';
      case 'video':
        return '🎥 Video';
      case 'voice':
        return '🎤 Voice message';
      default:
        return body;
    }
  }

  @pragma('vm:entry-point')
  static void _onNotificationTapped(NotificationResponse response) {
    _handleTap(response);
  }

  @pragma('vm:entry-point')
  static void _onBgNotificationTapped(NotificationResponse response) {
    _handleTap(response);
  }

  static void _handleTap(NotificationResponse response) {
    if (response.payload == null) return;
    final payload = response.payload!;

    if (payload.startsWith('call|')) {
      final parts = payload.split('|');
      if (parts.length >= 6) {
        final callId = parts[1];
        final callerId = parts[2];
        final callerName = parts[3];
        final callerAvatar = parts[4];
        final callType = parts[5];

        if (response.actionId == 'decline_call') {
          _rejectCallViaRest(callId);
          return;
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigatorKey.currentState?.pushNamed(
            AppRoutes.incomingCallRoute,
            arguments: {
              'callId': callId,
              'callerId': callerId,
              'callerName': callerName,
              'callerAvatar': callerAvatar,
              'callType': callType,
            },
          );
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

    if (notifType == 'group_message') {
      navigatorKey.currentState?.pushNamed(
        AppRoutes.groupChatRoute,
        arguments: {'groupId': data['groupId'], 'groupName': data['groupName']},
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
}
