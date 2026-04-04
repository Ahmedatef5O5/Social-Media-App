import 'package:cached_network_image/cached_network_image.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:social_media_app/core/router/app_router.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/core/secrets/app_secrets.dart';
import 'package:social_media_app/core/themes/cubit/theme_cubit.dart';
import 'package:social_media_app/features/auth/services/supabase_auth_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/auth/cubit/auth_cubit/auth_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await CachedNetworkImage.evictFromCache('');
  } catch (_) {}

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await dotenv.load(fileName: '.env');
  await Supabase.initialize(
    url: AppSecrets.supabaseUrl,
    anonKey: AppSecrets.supabaseAnonKey,
  );

  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    final session = data.session;
    if (session != null) {
      debugPrint('✅ Logged in successfully: ${session.user.email}');
    }
  });

  runApp(
    BlocProvider(
      create: (context) => AuthCubit(SupabaseAuthServices())..checkAuthStatus(),
      child: DevicePreview(
        enabled: !kReleaseMode,
        builder: (BuildContext context) => MyApp(),
      ),
    ),
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
            onUnknownRoute: (settings) => AppRouter.generateRoute(settings),
          );
        },
      ),
    );
  }
}
