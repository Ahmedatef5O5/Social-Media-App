import 'package:device_preview/device_preview.dart';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_media_app/core/router/app_router.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/core/secrets/app_secrets.dart';
import 'package:social_media_app/core/services/active_screen_tracker.dart';
import 'package:social_media_app/core/services/notification_services.dart';
import 'package:social_media_app/core/themes/cubit/theme_cubit.dart';
import 'package:social_media_app/features/auth/services/supabase_auth_services.dart';
import 'package:social_media_app/features/calls/cubit/call_cubit.dart';
import 'package:social_media_app/features/calls/cubit/call_state.dart';
import 'package:social_media_app/features/calls/model/call_model.dart';
import 'package:social_media_app/features/calls/services/call_signaling_service.dart';
import 'package:social_media_app/features/group_chat/cubit/group_list_cubit/group_list_cubit.dart';
import 'package:social_media_app/features/group_chat/services/group_chat_services.dart';
import 'package:social_media_app/firebase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/services/presence_service.dart';
import 'features/auth/cubit/auth_cubit/auth_cubit.dart';
import 'features/chats/services/chat_services.dart';
import 'features/home/cubits/home_cubit/home_cubit.dart';
import 'features/home/services/home_services.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final type = message.data['notificationType'] as String? ?? 'chat';

  if (type == 'incoming_call') {
    final plugin = FlutterLocalNotificationsPlugin();

    const androidInit = AndroidInitializationSettings(
      '@drawable/ic_notification',
    );
    await plugin.initialize(
      const InitializationSettings(android: androidInit),
      onDidReceiveBackgroundNotificationResponse: _bgNotificationTapped,
    );

    final androidPlugin =
        plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    final callChannel = AndroidNotificationChannel(
      'incoming_call_channel',
      'Incoming Calls',
      importance: Importance.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('incoming_ring'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
    );
    await androidPlugin?.createNotificationChannel(callChannel);

    final callId = message.data['callId'] ?? '';
    final callerId = message.data['callerId'] ?? '';
    final callerName = message.data['callerName'] ?? 'Unknown';
    final callerAvatar = message.data['callerAvatar'] ?? '';
    final callType = message.data['callType'] ?? 'audio';
    final subtitle =
        callType == 'video' ? 'Incoming video call' : 'Incoming voice call';

    Uint8List? avatarBytes;
    if (callerAvatar.isNotEmpty && callerAvatar.startsWith('http')) {
      try {
        final response = await dio_pkg.Dio().get<List<int>>(
          callerAvatar,
          options: dio_pkg.Options(responseType: dio_pkg.ResponseType.bytes),
        );
        if (response.data != null) {
          avatarBytes = Uint8List.fromList(response.data!);
        }
      } catch (_) {}
    }

    final androidDetails = AndroidNotificationDetails(
      'incoming_call_channel',
      'Incoming Calls',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.call,
      icon: '@drawable/ic_notification',
      largeIcon:
          avatarBytes != null ? ByteArrayAndroidBitmap(avatarBytes) : null,
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

    final supabaseUrl = message.data['supabaseUrl'] ?? '';
    final supabaseAnonKey = message.data['supabaseAnonKey'] ?? '';

    await plugin.show(
      callId.hashCode,
      callerName,
      subtitle,
      NotificationDetails(android: androidDetails),
      payload:
          'call|$callId|$callerId|$callerName|$callerAvatar|$callType|$supabaseUrl|$supabaseAnonKey',
    );
    return;
  }

  await NotificationService.instance.initialize(isBackground: true);
  await NotificationService.instance.showNotificationFromMessage(message);
}

@pragma('vm:entry-point')
void _bgNotificationTapped(NotificationResponse response) {
  final payload = response.payload ?? '';
  final actionId = response.actionId;

  if (payload.startsWith('call|') && actionId == 'decline_call') {
    final parts = payload.split('|');
    if (parts.length >= 8) {
      final callId = parts[1];
      final supabaseUrl = parts[6];
      final anonKey = parts[7];
      if (supabaseUrl.isNotEmpty && anonKey.isNotEmpty) {
        _rejectCallRest(callId, supabaseUrl, anonKey);
      }
    }
  }
}

Future<void> _rejectCallRest(
  String callId,
  String supabaseUrl,
  String anonKey,
) async {
  try {
    await dio_pkg.Dio().patch(
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
    debugPrint('Background call reject error: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initializeApp();

  final prefs = await SharedPreferences.getInstance();

  final String savedTheme = prefs.getString('user_theme_key') ?? 'ocean';

  runApp(_buildApp(savedTheme));
}

void _setupAuthListener() {
  Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
    final event = data.event;
    final session = data.session;

    if (event == AuthChangeEvent.signedIn && session != null) {
      debugPrint('✅ Logged in: ${session.user.email}');
      await PresenceService.instance.init();
    } else if (event == AuthChangeEvent.signedOut ||
        event == AuthChangeEvent.tokenRefreshed && session == null) {
      debugPrint('⚠️ Session expired or signed out. Redirecting to Login...');
      await PresenceService.instance.dispose();

      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.authRoute,
        (route) => false,
      );
    }
  });
}

Future<void> _initializeApp() async {
  await _lockOrientation();
  await _loadEnv();
  await _initFirebase();
  await _initSupabase();
  await _initNotifications();
  await PresenceService.instance.init();
  _setupAuthListener();
}

Future<void> _lockOrientation() async {
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}

Future<void> _loadEnv() async {
  await dotenv.load(fileName: '.env');
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

Widget _buildApp(String savedTheme) {
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider(create: (_) => HomeServices()),
      RepositoryProvider(create: (_) => ChatServices()),
      RepositoryProvider(create: (_) => SupabaseAuthServices()),

      RepositoryProvider(create: (_) => CallSignalingService()),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AuthCubit(SupabaseAuthServices())..checkAuthStatus(),
        ),
        BlocProvider(create: (context) => HomeCubit()..getHomeData()),
        BlocProvider(create: (_) => GroupListCubit(GroupChatServices())),

        BlocProvider(
          create: (context) => CallCubit(context.read<CallSignalingService>()),
        ),
      ],
      child: DevicePreview(
        enabled: !kReleaseMode,
        builder: (_) => MyApp(savedTheme: savedTheme),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String savedTheme;
  const MyApp({super.key, required this.savedTheme});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      lazy: false,
      create: (_) {
        final cubit = ThemeCubit(initialTheme: savedTheme);
        final user = Supabase.instance.client.auth.currentUser;

        if (user != null) {
          cubit.loaderUserTheme(user.id);
        }

        return cubit;
      },
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, state) {
          return MaterialApp(
            locale: DevicePreview.locale(context),
            builder: (ctx, child) {
              final devicePreviewChild = DevicePreview.appBuilder(ctx, child);
              return BlocListener<CallCubit, CallState>(
                listener: (context, callState) async {
                  final nav = navigatorKey.currentState;
                  if (nav == null) return;

                  if (callState is CallIncomingState) {
                    nav.pushNamed(
                      AppRoutes.incomingCallRoute,
                      arguments: {
                        'callId': callState.call.callId,
                        'callerId': callState.call.callerId,
                        'callerName': callState.call.callerName,
                        'callerAvatar': callState.call.callerAvatar,
                        'callType':
                            callState.call.type == CallType.video
                                ? 'video'
                                : 'audio',
                      },
                    );
                  } else if (callState is CallDialingState) {
                    nav.pushNamed(
                      AppRoutes.dialingRoute,
                      arguments: callState.call,
                    );
                  } else if (callState is CallConnectedState) {
                    final currentUser =
                        Supabase.instance.client.auth.currentUser;
                    if (currentUser == null) return;

                    final userData =
                        await Supabase.instance.client
                            .from('users')
                            .select('name')
                            .eq('id', currentUser.id)
                            .maybeSingle();

                    final currentUserName =
                        (userData?['name'] as String?) ?? 'Unknown';

                    nav.pushReplacementNamed(
                      AppRoutes.callRoute,
                      arguments: {
                        'call': callState.call,
                        'userId': currentUser.id,
                        'userName': currentUserName,
                      },
                    );
                  } else if (callState is CallEndedState) {
                    nav.popUntil((route) {
                      return route.settings.name != AppRoutes.callRoute &&
                          route.settings.name != AppRoutes.dialingRoute;
                    });
                  }
                },
                child: devicePreviewChild,
              );
            },
            debugShowCheckedModeBanner: false,
            title: 'Social Media App',
            theme: state.theme.themeData,
            initialRoute: AppRoutes.splashViewRoute,
            onGenerateRoute: AppRouter.generateRoute,
            onUnknownRoute: AppRouter.generateRoute,
            navigatorKey: navigatorKey,
            navigatorObservers: [_RouteObserver(), routeObserver],
          );
        },
      ),
    );
  }
}

class _RouteObserver extends NavigatorObserver {
  void _update(Route? route) {
    if (route?.settings.name != null) {
      ActiveScreenTracker.setCurrentRoute(route!.settings.name!);
    }
  }

  @override
  void didPush(Route route, Route? previousRoute) => _update(route);
  @override
  void didPop(Route route, Route? previousRoute) => _update(previousRoute);
  @override
  void didReplace({Route? newRoute, Route? oldRoute}) => _update(newRoute);
}
