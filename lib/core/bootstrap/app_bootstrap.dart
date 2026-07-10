import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_media_app/core/cache/services/hive_cache_manager.dart';
import 'package:social_media_app/core/cache/services/local_snapshot_store.dart';
import 'package:social_media_app/core/firebase/firebase_background_handlers.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/core/secrets/app_secrets.dart';
import 'package:social_media_app/core/services/network_status_service.dart';
import 'package:social_media_app/core/services/notification_services.dart';
import 'package:social_media_app/core/services/presence_service.dart';
import 'package:social_media_app/features/settings/repository/settings_repository.dart';
import 'package:social_media_app/firebase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> initializeApp() async {
  await _lockOrientation();
  AppSecrets.assertSecretsLoaded();
  await SettingsRepository.instance.init();
  await _initHiveCache();
  await _initFirebase();
  await _initSupabase();
  await _initNotifications();
  await PresenceService.instance.init();
  _setupAuthListener();
}

void _setupAuthListener() {
  Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
    final event = data.event;
    final session = data.session;

    if (event == AuthChangeEvent.signedIn && session != null) {
      debugPrint('✅ Logged in: ${session.user.email}');
      await PresenceService.instance.init();
      return;
    }
    final bool looksLikeSignOut =
        event == AuthChangeEvent.signedOut ||
        (event == AuthChangeEvent.tokenRefreshed && session == null);

    if (!looksLikeSignOut) {
      return;
    }
    final bool isOnline = await NetworkStatusService.instance.isConnected();
    if (!isOnline) {
      debugPrint(
        '⚠️ Auth event ($event) received while OFFLINE — ignoring, keeping cached session.',
      );
      return;
    }

    debugPrint('⚠️ Session expired or signed out. Redirecting to Login...');
    await PresenceService.instance.dispose();

    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      AppRoutes.authRoute,
      (route) => false,
    );
  });
}

Future<void> _initHiveCache() async {
  await HiveCacheManager.instance.init();
  await LocalSnapshotStore.instance.init();
}

Future<void> _lockOrientation() async {
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}

Future<void> _initFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    criticalAlert: true,
  );

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
}

Future<void> _initSupabase() async {
  await Supabase.initialize(
    url: AppSecrets.supabaseUrl,
    anonKey: AppSecrets.supabaseAnonKey,
  );
}

Future<void> _initNotifications() async {
  await NotificationService.instance.initialize();
}
