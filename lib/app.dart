import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:social_media_app/core/router/app_router.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/core/services/active_screen_tracker.dart';
import 'package:social_media_app/core/services/call_foreground_task_handler.dart';
import 'package:social_media_app/core/notifications/notification_service.dart';
import 'package:social_media_app/core/supabase/supabase_provider.dart';
import 'package:social_media_app/core/themes/cubits/theme_cubit.dart';
import 'package:social_media_app/core/widgets/calls/active_call_header_widget.dart';
import 'package:social_media_app/features/single_calls/cubits/single_call_cubit/call_cubit.dart';
import 'package:social_media_app/features/single_calls/models/call_model.dart';
import 'package:social_media_app/features/settings/widgets/app_lock_gate.dart';
import 'package:social_media_app/di/cubit_providers.dart';
import 'package:social_media_app/di/service_providers.dart';
import 'core/connectivity/cubits/connectivity_cubit.dart';
import 'core/connectivity/cubits/connectivity_state.dart';
import 'core/connectivity/widgets/connectivity_banner.dart';
import 'core/presence/services/presence_service.dart';
import 'core/services/active_call/cubit/active_call_session_cubit.dart';
import 'core/services/active_call/pip/call_pip_cubit.dart';
import 'core/services/global_group_call_listener.dart';
import 'core/services/incoming_call_navigation_guard.dart';
import 'core/toast/app_toast_overlay.dart';
import 'core/widgets/calls/call_pip_overlay.dart';

Widget buildApp(String savedTheme) {
  return MultiRepositoryProvider(
    providers: ServiceProviders.all,
    child: MultiBlocProvider(
      providers: CubitProviders.primary,

      child: DevicePreview(
        enabled: kDebugMode,
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
      create: CubitProviders.themeCubitCreate(savedTheme),
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, state) {
          return MultiBlocProvider(
            providers: CubitProviders.themeScoped,
            child: MaterialApp(
              locale: DevicePreview.locale(context),
              builder: (ctx, child) {
                Widget activeChild = DevicePreview.appBuilder(ctx, child);

                return AppLockGate(
                  child: GlobalGroupCallListener(
                    child: MultiBlocListener(
                      listeners: [
                        BlocListener<CallCubit, CallState>(
                          listener: (context, callState) async {
                            final nav = navigatorKey.currentState;
                            if (nav == null) return;

                            if (callState is CallIncomingState) {
                              final callId = callState.call.callId;
                              if (!IncomingCallNavigationGuard.claim(callId)) {
                                return;
                              }
                              nav
                                  .pushNamed(
                                    AppRoutes.incomingCallRoute,
                                    arguments: {
                                      'callId': callState.call.callId,
                                      'callerId': callState.call.callerId,
                                      'callerName': callState.call.callerName,
                                      'callerAvatar':
                                          callState.call.callerAvatar,
                                      'callType':
                                          callState.call.type == CallType.video
                                              ? 'video'
                                              : 'audio',
                                    },
                                  )
                                  .then(
                                    (_) => IncomingCallNavigationGuard.release(
                                      callId,
                                    ),
                                  );
                            } else if (callState is CallDialingState) {
                              nav.pushNamed(
                                AppRoutes.dialingRoute,
                                arguments: callState.call,
                              );
                            } else if (callState is CallConnectedState) {
                              final currentUser = SupabaseProvider.user;
                              if (currentUser == null) return;

                              final isCaller =
                                  callState.call.callerId == currentUser.id;
                              context
                                  .read<ActiveCallSessionCubit>()
                                  .startSingleCallSession(
                                    callId: callState.call.callId,
                                    title:
                                        isCaller
                                            ? callState.call.receiverName
                                            : callState.call.callerName,
                                    avatarUrl:
                                        isCaller
                                            ? callState.call.receiverAvatar
                                            : callState.call.callerAvatar,
                                    isVideo:
                                        callState.call.type == CallType.video,
                                    startedAt: DateTime.now(),
                                  );

                              nav.pushReplacementNamed(
                                AppRoutes.callRoute,
                                arguments: {
                                  'call': callState.call,
                                  'userId': currentUser.id,
                                  'userName': callState.currentUserName,
                                },
                              );
                              await FlutterForegroundTask.startService(
                                serviceId: 101,
                                notificationTitle: 'Ongoing Call',
                                notificationText: 'Tap to return to the call',
                                callback:
                                    startCallServiceCallback, // top-level function to be added in core/services
                              );
                            } else if (callState is CallEndedState) {
                              context
                                  .read<ActiveCallSessionCubit>()
                                  .endSession();
                              await context.read<CallPipCubit>().reset();

                              await FlutterForegroundTask.stopService();
                              nav.popUntil((route) {
                                return route.settings.name !=
                                        AppRoutes.callRoute &&
                                    route.settings.name !=
                                        AppRoutes.dialingRoute;
                              });
                            }
                          },
                        ),
                        BlocListener<ConnectivityCubit, ConnectivityState>(
                          listener: (context, connState) {
                            if (connState is ConnectivityRestored) {
                              PresenceService.instance.forceSyncNow();
                            }
                          },
                        ),
                      ],
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Stack(
                          children: [
                            activeChild,
                            const Directionality(
                              textDirection: TextDirection.ltr,
                              child: ConnectivityBanner(),
                            ),
                            const AppToastOverlay(),
                            const CallPipOverlay(), // 1:1 + group calls (LiveKit)
                            const ActiveCallHeaderWidget(),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
              debugShowCheckedModeBanner: false,
              title: 'Social Media App',
              theme: state.theme.themeData,
              initialRoute: AppRoutes.splashViewRoute,
              onGenerateInitialRoutes:
                  (initialRoute) => [
                    AppRouter.generateRoute(
                      const RouteSettings(name: AppRoutes.splashViewRoute),
                    ),
                  ],
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
