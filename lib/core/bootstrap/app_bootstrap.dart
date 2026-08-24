import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:social_media_app/core/cache/services/hive_cache_manager.dart';
import 'package:social_media_app/core/cache/services/local_snapshot_store.dart';
import 'package:social_media_app/core/firebase/firebase_background_handlers.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/core/secrets/app_secrets.dart';
import 'package:social_media_app/core/services/network_status_service.dart';
import 'package:social_media_app/core/services/notification_services.dart';
import 'package:social_media_app/core/presence/services/presence_service.dart';
import 'package:social_media_app/features/settings/repository/settings_repository.dart';
import 'package:social_media_app/firebase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/home/cubits/home_cubit/home_cubit.dart';
import '../../features/posts/cubit/posts_cubit/posts_cubit.dart';
import '../../features/stories/cubit/stories_cubit/stories_cubit.dart';
import '../errors/supabase_error_mapper.dart';
import '../share_intent/services/share_intent_service.dart';
import '../supabase/supabase_provider.dart';
import '../toast/app_toast.dart';

Future<void> initializeApp() async {
  await _lockOrientation();
  AppSecrets.assertSecretsLoaded();
  await SettingsRepository.instance.init();
  await _initHiveCache();
  await _initSupabase();
  await _safely('Firebase', _initFirebase);
  await _safely('Notifications', _initNotifications);
  await _safely('ShareIntent', ShareIntentService.instance.init);
  _initForegroundTask();
  await _safely('Presence', PresenceService.instance.init);

  _setupAuthListener();
}

Future<void> _safely(String label, Future<void> Function() step) async {
  try {
    await step();
  } catch (e, s) {
    debugPrint('⚠️ Non-critical bootstrap step "$label" failed: $e\n$s');
  }
}

void _setupAuthListener() {
  SupabaseProvider.authChanges.listen(
    (data) async {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        debugPrint('✅ Logged in: ${session.user.email}');
        await PresenceService.instance.init();
        final context = navigatorKey.currentContext;

        if (context != null) {
          if (!context.mounted) return;
          _refetchSessionCubits(context);
        }
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
      final context = navigatorKey.currentContext;

      if (context != null) {
        if (!context.mounted) return;
        _resetSessionCubits(context);
      }

      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.authRoute,
        (route) => false,
      );
    },
    onError: (e, s) {
      debugPrint('⚠️ Auth stream error: $e\n$s');
      AppToast.error(SupabaseErrorMapper.toUserMessage(e));
    },
  );
}

void _resetSessionCubits(BuildContext context) {
  try {
    context.read<HomeCubit>().resetSession();
    context.read<PostsCubit>().resetSession();
    context.read<StoriesCubit>().resetSession();
  } catch (e) {
    debugPrint('⚠️ Failed to reset session cubits on sign-out: $e');
  }
  unawaited(LocalSnapshotStore.instance.clearAll());
}

void _refetchSessionCubits(BuildContext context) {
  try {
    context.read<HomeCubit>().getCurrentUserData();
    context.read<PostsCubit>().fetchPosts();
    context.read<StoriesCubit>().fetchStories();
  } catch (e) {
    debugPrint('⚠️ Failed to refetch session cubits after sign-in: $e');
  }
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

Future<void> requestBatteryOptimizationExemptionIfNeeded() async {
  final alreadyIgnoring =
      await FlutterForegroundTask.isIgnoringBatteryOptimizations;
  if (alreadyIgnoring) return;

  await FlutterForegroundTask.requestIgnoreBatteryOptimization();
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

void _initForegroundTask() {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'ongoing_call_channel',
      channelName: 'Ongoing Call',
      channelDescription:
          'Shown while a voice or video call is active and the app is in the background.',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
      onlyAlertOnce: true,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: false,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.nothing(),
      autoRunOnBoot: false,
      autoRunOnMyPackageReplaced: true,
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );
}
