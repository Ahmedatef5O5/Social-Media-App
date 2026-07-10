import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/cache/datasources/media_local_data_source_impl.dart';
import 'package:social_media_app/core/cache/eviction/cache_eviction_service.dart';
import 'package:social_media_app/core/cache/repository/media_cache_repository.dart';
import 'package:social_media_app/core/cache/repository/media_cache_repository_impl.dart';
import 'package:social_media_app/core/cache/services/hive_cache_manager.dart';
import 'package:social_media_app/core/connectivity/cubit/connectivity_cubit.dart';
import 'package:social_media_app/core/router/app_router.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/core/services/active_screen_tracker.dart';
import 'package:social_media_app/core/services/cloudinary_storage_services.dart';
import 'package:social_media_app/core/services/network_status_service.dart';
import 'package:social_media_app/core/services/notification_services.dart';
import 'package:social_media_app/core/themes/cubit/theme_cubit.dart';
import 'package:social_media_app/features/auth/services/supabase_auth_services.dart';
import 'package:social_media_app/features/comments/services/comments_service.dart';
import 'package:social_media_app/features/single_calls/cubits/single_call_cubit/call_cubit.dart';
import 'package:social_media_app/features/single_calls/cubits/single_call_cubit/call_state.dart';
import 'package:social_media_app/features/single_calls/model/call_model.dart';
import 'package:social_media_app/features/single_calls/services/call_signaling_service.dart';
import 'package:social_media_app/features/single_chats/cubit/chats_cubit/chats_cubit.dart';
import 'package:social_media_app/features/group_chats/cubit/group_list_cubit/group_list_cubit.dart';
import 'package:social_media_app/features/group_chats/services/group_chat_services.dart';
import 'package:social_media_app/features/posts/services/posts_services.dart';
import 'package:social_media_app/features/profile/services/user_services.dart';
import 'package:social_media_app/features/settings/widgets/app_lock_gate.dart';
import 'package:social_media_app/features/stories/cubit/stories_cubit/stories_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/connectivity/widgets/connectivity_banner.dart';
import 'core/services/global_group_call_listener.dart';
import 'features/auth/cubit/auth_cubit/auth_cubit.dart';
import 'features/posts/cubit/posts_cubit.dart';
import 'features/single_chats/services/chat_services.dart';
import 'features/discover/services/discover_people_services.dart';
import 'features/group_calls/services/group_call_signaling_service.dart';
import 'features/home/cubits/home_cubit/home_cubit.dart';

Widget buildApp(String savedTheme) {
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider(create: (_) => SupabaseAuthServices()),
      RepositoryProvider(create: (_) => ChatServices()),
      RepositoryProvider(create: (_) => GroupChatServices()),
      RepositoryProvider(create: (_) => CallSignalingService()),
      RepositoryProvider(create: (_) => UserService()),
      RepositoryProvider(create: (_) => CommentsService()),
      RepositoryProvider(create: (_) => PostsServices()),
      RepositoryProvider(create: (_) => CloudinaryStorageServices.instance),
      RepositoryProvider(create: (_) => DiscoverPeopleServices()),
      RepositoryProvider(create: (_) => GroupCallSignalingService()),
      RepositoryProvider<MediaCacheRepository>(
        create: (_) {
          final localDataSource = MediaLocalDataSourceImpl(
            box: HiveCacheManager.instance.mediaCacheBox,
            metaBox: HiveCacheManager.instance.cacheMetaBox,
          );

          final cacheEvictionService = CacheEvictionService(
            localDataSource: localDataSource,
            metaBox: HiveCacheManager.instance.cacheMetaBox,
          );
          return MediaCacheRepositoryImpl(
            localDataSource: localDataSource,
            evictionService: cacheEvictionService,
          )..initialize();
        },
      ),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider(
          create:
              (context) =>
                  AuthCubit(context.read<SupabaseAuthServices>())
                    ..checkAuthStatus(),
        ),
        BlocProvider(
          create:
              (context) => PostsCubit(
                postsServices: context.read<PostsServices>(),
                storage: context.read<CloudinaryStorageServices>(),
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
        BlocProvider(
          create:
              (context) => GroupListCubit(context.read<GroupChatServices>()),
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
              (context) =>
                  ChatsCubit(context.read<ChatServices>())..monitorChats(),
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
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create:
                    (context) => ConnectivityCubit(
                      networkStatus: NetworkStatusService.instance,
                    ),
              ),
            ],
            child: MaterialApp(
              locale: DevicePreview.locale(context),
              builder: (ctx, child) {
                final devicePreviewChild = DevicePreview.appBuilder(ctx, child);
                return AppLockGate(
                  child: GlobalGroupCallListener(
                    child: BlocListener<CallCubit, CallState>(
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
                      child: Stack(
                        children: [
                          devicePreviewChild,
                          const Directionality(
                            textDirection: TextDirection.ltr,
                            child: ConnectivityBanner(),
                          ),
                        ],
                      ),
                    ),
                  ),
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
            ),
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
