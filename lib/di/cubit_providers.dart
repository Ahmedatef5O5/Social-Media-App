import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/connectivity/cubits/connectivity_cubit.dart';
import 'package:social_media_app/core/presence/cubits/presence_cubit/presence_cubit.dart';
import 'package:social_media_app/core/services/active_call/cubits/active_call_session_cubit.dart';
import 'package:social_media_app/core/services/active_call/pip/call_pip_cubit.dart';
import 'package:social_media_app/core/services/network_status_service.dart';
import 'package:social_media_app/core/themes/cubits/theme_cubit.dart';
import 'package:social_media_app/features/ai_assistant/cubits/ai_preferences_cubit/ai_preferences_cubit.dart';
import 'package:social_media_app/features/auth/cubits/auth_cubit/auth_cubit.dart';
import 'package:social_media_app/features/auth/services/supabase_auth_services.dart';

class CubitProviders {
  CubitProviders._();

  static final primary = [
    BlocProvider(
      create:
          (context) =>
              AuthCubit(context.read<SupabaseAuthServices>())
                ..checkAuthStatus(),
    ),
    BlocProvider(create: (_) => CallPipCubit()),
    BlocProvider(create: (_) => ActiveCallSessionCubit(), lazy: false),
    BlocProvider(create: (_) => AiPreferencesCubit()..init(), lazy: false),
  ];

  static final themeScoped = [
    BlocProvider(
      create:
          (context) =>
              ConnectivityCubit(networkStatus: NetworkStatusService.instance),
    ),
    BlocProvider(create: (_) => PresenceCubit(), lazy: false),
  ];

  static ThemeCubit Function(BuildContext) themeCubitCreate(String savedTheme) {
    return (_) => ThemeCubit(initialTheme: savedTheme);
  }
}
