import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/cache/repository/media_cache_repository.dart';
import 'package:social_media_app/core/connectivity/cubits/connectivity_cubit.dart';
import 'package:social_media_app/core/presence/cubit/presence_cubit/presence_cubit.dart';
import 'package:social_media_app/core/services/active_call/cubit/active_call_session_cubit.dart';
import 'package:social_media_app/core/services/active_call/pip/call_pip_cubit.dart';
import 'package:social_media_app/core/services/cloudinary_storage_services.dart';
import 'package:social_media_app/core/services/network_status_service.dart';
import 'package:social_media_app/core/supabase/supabase_provider.dart';
import 'package:social_media_app/core/themes/cubits/theme_cubit.dart';
import 'package:social_media_app/features/ai_assistant/cubits/ai_preferences_cubit/ai_preferences_cubit.dart';
import 'package:social_media_app/features/auth/cubits/auth_cubit/auth_cubit.dart';
import 'package:social_media_app/features/auth/services/supabase_auth_services.dart';
import 'package:social_media_app/features/group_chats/cubits/group_list_cubit/group_list_cubit.dart';
import 'package:social_media_app/features/group_chats/services/group_chat_services.dart';
import 'package:social_media_app/features/home/cubits/home_cubit/home_cubit.dart';
import 'package:social_media_app/features/posts/cubits/posts_cubit/posts_cubit.dart';
import 'package:social_media_app/features/posts/services/posts_services.dart';
import 'package:social_media_app/features/profile/services/user_services.dart';
import 'package:social_media_app/features/reels/cubits/reels_feed_cubit/reels_feed_cubit.dart';
import 'package:social_media_app/features/single_calls/cubits/single_call_cubit/call_cubit.dart';
import 'package:social_media_app/features/single_calls/services/call_signaling_service.dart';
import 'package:social_media_app/features/single_chats/cubits/chats_cubit/chats_cubit.dart';
import 'package:social_media_app/features/single_chats/services/chat_services.dart';
import 'package:social_media_app/features/stories/cubits/stories_cubit/stories_cubit.dart';

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
    BlocProvider(create: (_) => AiPreferencesCubit()..init(), lazy: false),
    BlocProvider(
      create:
          (context) => PostsCubit(
            postsServices: context.read<PostsServices>(),
            storage: context.read<CloudinaryStorageServices>(),
            mediaCacheRepository: context.read<MediaCacheRepository>(),
          )..fetchPosts(),
    ),
    BlocProvider(
      create:
          (context) => HomeCubit(
            userService: context.read<UserService>(),
            postsCubit: context.read<PostsCubit>(),
          )..getCurrentUserData(),
    ),
    BlocProvider(create: (context) => StoriesCubit()..fetchStories()),
    BlocProvider(create: (context) => ReelsFeedCubit()),
    BlocProvider(
      create:
          (context) =>
              GroupListCubit(context.read<GroupChatServices>())
                ..monitorGroups(),
    ),
    BlocProvider(
      create:
          (context) => CallCubit(
            signalingService: context.read<CallSignalingService>(),
            chatServices: context.read<ChatServices>(),
          ),
    ),
    BlocProvider(
      create:
          (context) => ChatsCubit(context.read<ChatServices>())..monitorChats(),
    ),
  ];

  static final themeScoped = [
    BlocProvider(
      create:
          (context) =>
              ConnectivityCubit(networkStatus: NetworkStatusService.instance),
    ),
    BlocProvider(create: (_) => PresenceCubit(), lazy: false),
    BlocProvider(create: (_) => ActiveCallSessionCubit()),
  ];

  static ThemeCubit Function(BuildContext) themeCubitCreate(String savedTheme) {
    return (_) {
      final cubit = ThemeCubit(initialTheme: savedTheme);
      final user = SupabaseProvider.user;

      if (user != null) {
        cubit.loaderUserTheme(user.id);
      }

      return cubit;
    };
  }
}
