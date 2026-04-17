import 'dart:ui' as ui;
import 'package:dio/dio.dart' as dio_pkg;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:social_media_app/core/services/active_screen_tracker.dart';
import '../../features/chats/models/chat_user_model.dart';
import '../router/app_routes.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static final Map<String, List<Message>> _messagesBySender = {};
  static final Map<String, Uint8List> _avatarCache = {};

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

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_messageChannel);

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

  Future<void> _requestPermissions() async {
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  void _listenToForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final senderId = message.data['senderId'] as String?;
      if (senderId != null &&
          !ActiveScreenTracker.isViewingChatWith(senderId)) {
        await showNotificationFromMessage(message);
      }
    });
  }

  void _listenToNotificationOpenedApp() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _navigateFromMessage(message.data);
    });
  }

  Future<void> _handleTerminatedAppLaunch() async {
    final message = await _fcm.getInitialMessage();
    if (message != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateFromMessage(message.data);
      });
    }
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

  static void _onNotificationTapped(NotificationResponse response) {
    if (response.payload == null) return;
    final parts = response.payload!.split('|');
    if (parts.length >= 2) {
      _navigateFromMessage({
        'senderId': parts[0],
        'senderName': parts[1],
        'senderImageUrl': parts.length > 2 ? parts[2] : null,
      });
    }
  }

  static void _navigateFromMessage(Map<String, dynamic> data) {
    final user = ChatUserModel(
      id: data['senderId'],
      name: data['senderName'],
      imageUrl: data['senderImageUrl'],
    );
    navigatorKey.currentState?.pushNamed(
      AppRoutes.chatDetailsViewRoute,
      arguments: user,
    );
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
