import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_media_app/core/bootstrap/session_data_cleaner.dart';
import 'package:social_media_app/core/cache/services/hive_cache_manager.dart';
import 'package:social_media_app/core/cache/services/local_snapshot_store.dart';
import 'package:social_media_app/core/firebase/firebase_background_handlers.dart';
import 'package:social_media_app/core/notifications/handlers/tap_action_handler.dart';
import 'package:social_media_app/core/presence/services/presence_service.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/core/secrets/app_secrets.dart';
import 'package:social_media_app/core/services/incoming_call_navigation_guard.dart';
import 'package:social_media_app/core/services/network_status_service.dart';
import 'package:social_media_app/core/services/permissions/app_permissions_service.dart';
import 'package:social_media_app/features/settings/repository/settings_repository.dart';
import 'package:social_media_app/firebase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/services/auth_link_handler.dart';
import '../../features/auth/services/auth_recovery_coordinator.dart';
import '../../features/home/cubits/home_cubit/home_cubit.dart';
import '../../features/posts/cubits/posts_cubit/posts_cubit.dart';
import '../../features/stories/cubits/stories_cubit/stories_cubit.dart';
import '../deep_link/services/deep_link_service.dart';
import '../errors/supabase_error_mapper.dart';
import '../notifications/notification_service.dart';
import '../observability/build_info.dart';
import '../observability/crashlytics_reporter.dart';
import '../observability/observability.dart';
import '../observability/realtime_channel_sampler.dart';
import '../observability/realtime_diagnostics.dart';
import '../services/active_screen_tracker.dart';
import '../session/session_guard.dart';
import '../session/session_scope.dart';
import '../share_intent/services/share_intent_service.dart';
import '../supabase/supabase_provider.dart';
import '../toast/app_toast.dart';

Future<void> initializeCriticalBeforeRunApp() async {
  _configureImageCache();
  await _lockOrientation();

  // Opens the main-isolate end of the foreground-service communication port.
  // Must run before `runApp` — it is how the "Ongoing Call" notification tells
  // the UI isolate to expand the minimized call (see `CallForegroundTaskHandler`
  // and `app.dart`). Synchronous and cheap; never allowed to block startup.
  try {
    FlutterForegroundTask.initCommunicationPort();
  } catch (e, s) {
    debugPrint('⚠️ initCommunicationPort failed: $e\n$s');
  }

  // Firebase Core moved UP from `initializeCoreServices()`.
  //
  // `main.dart` installs FlutterError.onError / PlatformDispatcher.onError
  // on its very first lines, long before this runs. `Observability` buffers
  // everything until the line below attaches the real reporter, so nothing
  // is lost — but the window must stay as short as possible, which is why
  // Firebase now initialises here instead of after runApp().
  //
  // Wrapped in `_safely`: a Firebase outage must never prevent the app from
  // starting. Losing telemetry is acceptable; losing the app is not.
  await _safely('FirebaseCore', _initFirebaseCore);
  await _safely('Observability', _initObservability);
  await Future.wait([
    _safely('Supabase', _initSupabase),
    _safely('HiveCache', _initHiveCache),
    // The saved UI language must be known before the first frame, otherwise an
    // Arabic user would see one English frame (and mirrored layout would pop).
    // SharedPreferences read only; `init()` is idempotent, so the later call in
    // `initializeCoreServices()` is a no-op.
    _safely('Settings', SettingsRepository.instance.init),
  ]);
}

/// Bounds Flutter's in-memory cache of DECODED images (bitmaps).
void _configureImageCache() {
  final cache = PaintingBinding.instance.imageCache;
  cache.maximumSizeBytes = 64 << 20; // 64 MiB (default 100 MiB)
  cache.maximumSize = 300; // entries (default 1000)
}

Future<void> _initObservability() async {
  await obs.attachReporter(
    CrashlyticsReporter(),
    environment: BuildInfo.environment,
    appVersion: BuildInfo.appVersion,
    buildNumber: BuildInfo.buildNumber,
    collectionEnabled: !kDebugMode,
  );
  await obs.setContext('commit_sha', BuildInfo.commitSha);
}

Completer<void>? _coreServicesCompleter;

Future<void> startCoreServicesBootstrap() {
  final existing = _coreServicesCompleter;
  if (existing != null) return existing.future;

  final completer = Completer<void>();
  _coreServicesCompleter = completer;

  initializeCoreServices().then((_) => completer.complete()).catchError((e, s) {
    debugPrint('⚠️ Critical bootstrap failure: $e\n$s');
    // Never leave SplashView waiting forever on a bootstrap bug —
    // individual steps already fail safely on their own via
    // `_safely`, so completing here just unblocks navigation.
    completer.complete();
  });

  return completer.future;
}

Future<void> waitForCoreServicesReady() {
  return _coreServicesCompleter?.future ?? startCoreServicesBootstrap();
}

/// True once `Supabase.initialize` has completed in this isolate.
bool _isSupabaseReady() {
  try {
    Supabase.instance.client;
    return true;
  } catch (_) {
    return false;
  }
}

Future<void> initializeCoreServices() async {
  AppSecrets.assertSecretsLoaded();

  // A brand-new UI isolate cannot be in a call, so a mirrored "busy" flag from
  // a previous process is stale by definition.
  unawaited(
    _safely(
      'ClearCallBusyState',
      IncomingCallNavigationGuard.clearPersistedBusyState,
    ),
  );

  // Was this process started by tapping a call notification? Answered BEFORE
  // core services complete so `SplashView` can skip its animation delay and
  // the tap can be queued for HomeView instead of being wiped by the splash.
  await _safely(
    'ColdStartLaunch',
    TapActionHandler.instance.detectColdStartLaunch,
  );

  // Group A - fully independent: each touches a different storage/plugin
  // (Hive, Supabase SDK, SharedPreferences). Safe to run in parallel.
  final coreReady = Future.wait([
    _safely('HiveCache', _initHiveCache),
    _safely('Supabase', _initSupabase),
    _safely('Settings', SettingsRepository.instance.init),
  ]);

  // Group C - Firebase CORE has MOVED to initializeCriticalBeforeRunApp()
  // so Crashlytics exists before the first frame. Do not re-add it here:
  // Firebase.initializeApp() throws on a duplicate [DEFAULT] app.

  final shareIntentReady = _safely(
    'ShareIntent',
    ShareIntentService.instance.init,
  );
  final deepLinkReady = _safely('DeepLink', DeepLinkService.instance.init);

  await Future.wait([coreReady, shareIntentReady, deepLinkReady]);

  final supabaseReady = _isSupabaseReady();
  await obs.setContext('supabase_ready', supabaseReady);

  if (supabaseReady) {
    await _safely('AuthRecoveryRestore', AuthRecoveryCoordinator.restore);
    await _safely('AuthLinkHandler', AuthLinkHandler.instance.init);
    await _safely(
      'ObservabilitySessionUser',
      () => obs.setSessionUser(SupabaseProvider.idOrNull),
    );
    await _safely('CrossAccountCacheGuard', _guardAgainstCrossAccountCacheLeak);
  } else {
    await obs.breadcrumb(
      'supabase unavailable - session-bound bootstrap skipped',
      feature: 'bootstrap',
    );
  }

  await _safely(
    'ConsumeShare',
    ShareIntentService.instance.consumeInitialShareIfAny,
  );
  _initForegroundTask();

  if (supabaseReady) {
    await _safely('Presence', PresenceService.instance.init);
    RealtimeChannelSampler.instance.start();
    _setupAuthListener();
  }

  unawaited(_requestStartupPermissions());
  unawaited(_safely('Notifications', _initNotifications));
}

Future<void> _requestStartupPermissions() async {
  await _safely('FirebasePermissions', _requestFirebaseNotificationPermissions);
  await _safely(
    'MediaPermissions',
    AppPermissionsService.instance.requestInitialMediaPermissionsIfNeeded,
  );
}

Future<void> _safely(String label, Future<void> Function() step) async {
  try {
    await step();
  } catch (e, s) {
    debugPrint('⚠️ Non-critical bootstrap step "$label" failed: $e\n$s');
    unawaited(
      obs.recordError(
        e,
        s,
        feature: 'bootstrap',
        operation: label,
        reason: 'non-critical bootstrap step failed',
      ),
    );
  }
}

const String _kLocalSnapshotOwnerPrefsKey = 'local_snapshot_owner_user_id';

Future<void> _guardAgainstCrossAccountCacheLeak() async {
  final prefs = await SharedPreferences.getInstance();
  final cachedOwnerId = prefs.getString(_kLocalSnapshotOwnerPrefsKey);
  final currentUserId = SupabaseProvider.user?.id;

  if (cachedOwnerId != currentUserId) {
    debugPrint(
      '🧹 LocalSnapshotStore owner mismatch ("$cachedOwnerId" -> '
      '"$currentUserId") — clearing cached chats/groups/posts/etc. so '
      "one account's data never leaks into another's session.",
    );
    await LocalSnapshotStore.instance.clearAll();
    if (currentUserId != null) {
      await prefs.setString(_kLocalSnapshotOwnerPrefsKey, currentUserId);
    } else {
      await prefs.remove(_kLocalSnapshotOwnerPrefsKey);
    }
  }
}

Future<void> completeSignInBootstrap() async {
  final session = SupabaseProvider.currentSession;
  final userId = session?.user.id;
  if (userId != null) {
    await obs.setSessionUser(userId);
    await obs.breadcrumb(
      'mfa challenge completed - signed in',
      feature: 'auth',
    );
    RealtimeDiagnostics.instance.detectZombies(userId);
    RealtimeChannelSampler.instance.setOwner(userId);
    await PresenceService.instance.init();
    final context = navigatorKey.currentContext;
    if (context != null && context.mounted) {
      _refetchSessionCubits(context);
    }
  }
}

void _setupAuthListener() {
  SupabaseProvider.authChanges.listen(
    (data) async {
      final event = data.event;
      final session = data.session;

      // Snapshot BEFORE the owner changes, so channels opened by the
      // previous account are attributed to it and can be flagged as zombies.
      RealtimeChannelSampler.instance.sample();

      if (event == AuthChangeEvent.passwordRecovery) {
        debugPrint('ℹ️ AuthListener: Password recovery event received.');
        AuthRecoveryCoordinator.markRecoveryPending();
        AuthLinkHandler.instance.onAuthEvent();

        final nav = navigatorKey.currentState;
        if (nav != null &&
            ActiveScreenTracker.currentRoute != AppRoutes.splashViewRoute &&
            ActiveScreenTracker.currentRoute != AppRoutes.resetPasswordRoute) {
          nav.pushNamedAndRemoveUntil(
            AppRoutes.resetPasswordRoute,
            (route) => false,
          );
        }
        return;
      }

      if (event == AuthChangeEvent.signedIn && session != null) {
        AuthLinkHandler.instance.onAuthEvent();
        debugPrint('✅ Logged in: ${session.user.email}');

        if (SessionGuard.isMfaChallengePending) {
          debugPrint(
            '⏳ 2FA challenge pending; skipping session bootstrap until AAL2',
          );
          return;
        }

        await obs.setSessionUser(session.user.id);
        await obs.breadcrumb('signed in', feature: 'auth');
        RealtimeDiagnostics.instance.detectZombies(session.user.id);
        RealtimeChannelSampler.instance.setOwner(session.user.id);

        await PresenceService.instance.init();

        final context = navigatorKey.currentContext;
        if (context != null && context.mounted) {
          _refetchSessionCubits(context);
        }

        unawaited(
          _safely(
            'MediaPermissions',
            AppPermissionsService
                .instance
                .requestInitialMediaPermissionsIfNeeded,
          ),
        );
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
      await obs.breadcrumb('signed out ($event)', feature: 'auth');
      await obs.setSessionUser(null);
      RealtimeChannelSampler.instance.setOwner(null);
      await PresenceService.instance.dispose();

      try {
        await SupabaseProvider.client.removeAllChannels();
      } catch (e) {
        debugPrint('⚠️ removeAllChannels on sign out: $e');
      }
      RealtimeDiagnostics.instance.reset();

      final context = navigatorKey.currentContext;

      if (context != null && context.mounted) {
        _resetSessionCubits(context);
      }

      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.authRoute,
        (route) => false,
      );
    },
    onError: (e, s) {
      debugPrint('⚠️ Auth stream error: $e\n$s');
      if (AuthLinkHandler.instance.shouldSuppressAuthErrors) return;
      AppToast.error(SupabaseErrorMapper.toUserMessage(e));
    },
  );
}

/// Closes every account-scoped Cubit and wipes the local snapshots & session data.
void _resetSessionCubits(BuildContext context) {
  try {
    SessionScope.endSession(context);
  } catch (e) {
    debugPrint('⚠️ SessionScope.endSession failed: $e');
  }
  try {
    context.read<HomeCubit>().resetSession();
    context.read<PostsCubit>().resetSession();
    context.read<StoriesCubit>().resetSession();
  } catch (e) {
    debugPrint('⚠️ Failed to reset session cubits on sign-out: $e');
  }
  unawaited(SessionDataCleaner.clearOnSessionEnd());
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

Future<void> _initFirebaseCore() async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}

Future<void> _requestFirebaseNotificationPermissions() async {
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
  if (_isSupabaseReady()) return;
  AppSecrets.assertSecretsLoaded();
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
