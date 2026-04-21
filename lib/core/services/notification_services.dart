import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:dio/dio.dart' as dio_pkg;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/core/services/active_screen_tracker.dart';
import 'package:social_media_app/features/chats/models/chat_user_model.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static final Map<String, List<Message>> _messagesBySender = {};
  static final Map<String, Uint8List> _avatarCache = {};

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  bool _initialized = false;

  // ── Channels ──

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
      onDidReceiveBackgroundNotificationResponse: _onNotificationTapped,
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
    await _localNotifications.cancel(senderId.hashCode + 1);
    _messagesBySender.remove(senderId);
  }

  /// Cancel incoming call notification (called when call is answered or dismissed)
  Future<void> cancelCallNotification(String callId) async {
    await _localNotifications.cancel(callId.hashCode);
  }

  Future<void> _requestPermissions() async {
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  void _listenToForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final type = message.data['notificationType'] as String? ?? 'chat';

      if (type == 'incoming_call') {
        // Show call UI directly via navigatorKey
        await _handleIncomingCallData(message.data);
        return;
      }

      final senderId = message.data['senderId'] as String?;
      if (senderId != null &&
          !ActiveScreenTracker.isViewingChatWith(senderId)) {
        await showNotificationFromMessage(message);
      }
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
    final Uint8List profileBitmap = await _getAvatarBitmap(
      callerId,
      callerAvatar,
    );

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
      fullScreenIntent: true, // ← This wakes the screen
      ongoing: true, // Can't be swiped away
      autoCancel: false,
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

    // Also navigate in-app if app is open
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

    final senderId = data['senderId'] ?? '';
    final senderName =
        data['senderName'] ?? notification?.title ?? 'New Message';
    final body = data['messageBody'] ?? notification?.body ?? '';
    final avatarUrl = data['senderImageUrl'];
    final messageType = data['messageType'] ?? 'text';
    final messageImageUrl = data['messageImageUrl'];

    final Uint8List profileBitmap = await _getAvatarBitmap(senderId, avatarUrl);

    _messagesBySender.putIfAbsent(senderId, () => []);
    _messagesBySender[senderId]!.add(
      Message(
        messageType == 'image'
            ? '📷 Photo'
            : messageType == 'video'
            ? '🎥 Video'
            : messageType == 'voice'
            ? '🎤 Voice message'
            : body,
        DateTime.now(),
        Person(name: senderName, icon: ByteArrayAndroidIcon(profileBitmap)),
      ),
    );

    final messagingStyle = MessagingStyleInformation(
      Person(name: senderName, icon: ByteArrayAndroidIcon(profileBitmap)),
      conversationTitle: senderName,
      messages: _messagesBySender[senderId]!,
    );

    StyleInformation styleInformation;

    if (messageType == 'image') {
      final Uint8List? sentImageBytes = await _fetchBitmap(messageImageUrl);
      if (sentImageBytes != null) {
        styleInformation = BigPictureStyleInformation(
          ByteArrayAndroidBitmap(sentImageBytes),
          largeIcon: ByteArrayAndroidBitmap(profileBitmap),
          contentTitle: senderName,
          summaryText: '📷 Photo',
          hideExpandedLargeIcon: false,
        );
      } else {
        styleInformation = messagingStyle;
      }
    } else {
      styleInformation = messagingStyle;
    }

    final androidDetails = AndroidNotificationDetails(
      _messageChannel.id,
      _messageChannel.name,
      channelDescription: _messageChannel.description,
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.message,
      icon: '@drawable/ic_notification',
      styleInformation: styleInformation,
      groupKey: 'chat_$senderId',
      color: ThemeData().primaryColor,
    );

    await _localNotifications.show(
      senderId.hashCode,
      senderName,
      body,
      NotificationDetails(android: androidDetails),
      payload: '$senderId|$senderName|$avatarUrl',
    );

    await _localNotifications.show(
      senderId.hashCode + 1,
      '',
      '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _messageChannel.id,
          _messageChannel.name,
          groupKey: 'chat_$senderId',
          setAsGroupSummary: true,
          importance: Importance.low,
          icon: '@drawable/ic_notification',
        ),
      ),
    );
  }

  @pragma('vm:entry-point')
  static void _onNotificationTapped(NotificationResponse response) {
    if (response.payload == null) return;
    final payload = response.payload!;

    if (payload.startsWith('call|')) {
      final parts = payload.split('|');
      if (parts.length >= 6) {
        final actionId = response.actionId;
        if (actionId == 'decline_call') {
          return;
        }
        navigatorKey.currentState?.pushNamed(
          AppRoutes.incomingCallRoute,
          arguments: {
            'callId': parts[1],
            'callerId': parts[2],
            'callerName': parts[3],
            'callerAvatar': parts[4],
            'callType': parts[5],
          },
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

  Future<Uint8List> _makeCircularBitmap(Uint8List imageBytes) async {
    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final size = image.width < image.height ? image.width : image.height;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..isAntiAlias = true;
    final rect = Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble());
    canvas.clipPath(Path()..addOval(rect));
    canvas.drawImage(
      image,
      Offset(-(image.width - size) / 2, -(image.height - size) / 2),
      paint,
    );
    final picture = recorder.endRecording();
    final circularImage = await picture.toImage(size, size);
    final byteData = await circularImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return byteData!.buffer.asUint8List();
  }

  Future<Uint8List> _getAvatarBitmap(String senderId, String? imageUrl) async {
    if (_avatarCache.containsKey(senderId)) {
      return _avatarCache[senderId]!;
    }
    final raw = await _fetchBitmap(imageUrl);
    final bitmap = await _makeCircularBitmap(
      raw ?? await _loadFlutterAsset('assets/images/no_profile_picture.png'),
    );
    _avatarCache[senderId] = bitmap;
    return bitmap;
  }

  Future<Uint8List?> _fetchBitmap(String? url) async {
    if (url == null || url.isEmpty || !url.startsWith('http')) return null;
    try {
      final response = await dio_pkg.Dio().get<List<int>>(
        url,
        options: dio_pkg.Options(responseType: dio_pkg.ResponseType.bytes),
      );
      return response.data != null ? Uint8List.fromList(response.data!) : null;
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List> _loadFlutterAsset(String path) async {
    final byteData = await rootBundle.load(path);
    return byteData.buffer.asUint8List();
  }
}
