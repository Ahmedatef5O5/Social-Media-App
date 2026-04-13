import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:social_media_app/core/router/app_router.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/core/secrets/app_secrets.dart';
import 'package:social_media_app/core/services/active_screen_tracker.dart';
import 'package:social_media_app/core/services/notification_services.dart';
import 'package:social_media_app/core/themes/cubit/theme_cubit.dart';
import 'package:social_media_app/features/auth/services/supabase_auth_services.dart';
import 'package:social_media_app/firebase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/cubit/auth_cubit/auth_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initializeApp();

  runApp(_buildApp());
}

Future<void> _initializeApp() async {
  await _lockOrientation();
  await _loadEnv();
  await _initFirebase();
  await _initSupabase();
  await _initNotifications();
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

void _setupAuthListener() {
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    final session = data.session;
    if (session != null) {
      debugPrint('✅ Logged in: ${session.user.email}');
    }
  });
}

Widget _buildApp() {
  return BlocProvider(
    create: (_) => AuthCubit(SupabaseAuthServices())..checkAuthStatus(),
    child: DevicePreview(enabled: !kReleaseMode, builder: (_) => const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      lazy: false,
      create: (_) {
        final cubit = ThemeCubit();
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
            builder: DevicePreview.appBuilder,
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
