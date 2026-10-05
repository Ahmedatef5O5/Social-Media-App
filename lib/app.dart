import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:social_media_app/core/router/app_router.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/core/services/active_screen_tracker.dart';
import 'package:social_media_app/core/services/call_foreground_service.dart';
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
import 'core/services/active_call/call_navigation_helper.dart';
import 'core/services/active_call/cubits/active_call_session_cubit.dart';
import 'core/services/call_foreground_task_handler.dart';
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

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.savedTheme});

  final String savedTheme;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    FlutterForegroundTask.addTaskDataCallback(_onForegroundTaskData);
  }

  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_onForegroundTaskData);
    super.dispose();
  }

  /// Messages from `CallForegroundTaskHandler` (service isolate).
  ///
  /// `expand_active_call` == the user tapped "Tap to return to the call" in the
  /// system notification: if the call is currently minimized (PiP / header),
  /// bring the full-screen call view back.
  void _onForegroundTaskData(Object data) {
    final isExpandRequest =
        data == expandActiveCallMessage ||
        (data is Map && data['action'] == expandActiveCallMessage);
    if (!isExpandRequest) return;

    final context = navigatorKey.currentContext;
    if (context == null) return;

    try {
      final session = context.read<ActiveCallSessionCubit>().state;
      if (session == null) return;

      final pipCubit = context.read<CallPipCubit>();
      if (pipCubit.state.isMinimized) {
        CallNavigationHelper.expandActiveCall(pipCubit, session);
      }
    } catch (e) {
      debugPrint('[App] expand_active_call failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      lazy: false,
      create: CubitProviders.themeCubitCreate(widget.savedTheme),
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
                                    startedAt:
                                        callState.call.startTime?.toLocal() ??
                                        DateTime.now(),
                                    // Populated immediately so the ongoing-call
                                    // notification / header can expand the call
                                    // (CallNavigationHelper needs all three).
                                    call: callState.call,
                                    currentUserId: currentUser.id,
                                    currentUserName: callState.currentUserName,
                                  );

                              nav.pushReplacementNamed(
                                AppRoutes.callRoute,
                                arguments: {
                                  'call': callState.call,
                                  'userId': currentUser.id,
                                  'userName': callState.currentUserName,
                                },
                              );
                              await CallForegroundService.start(
                                serviceId: 101,
                                title: 'Ongoing Call',
                                text: 'Tap to return to the call',
                                isVideo: callState.call.type == CallType.video,
                              );
                            } else if (callState is CallEndedState) {
                              context
                                  .read<ActiveCallSessionCubit>()
                                  .endSession();
                              await context.read<CallPipCubit>().reset();

                              await CallForegroundService.stop();
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
              title: 'Social Mate',
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
  @override
  void didPop(Route route, Route? previousRoute) => _update(previousRoute);

  @override
  void didPush(Route route, Route? previousRoute) => _update(route);

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) => _update(newRoute);

  void _update(Route? route) {
    if (route?.settings.name != null) {
      ActiveScreenTracker.setCurrentRoute(route!.settings.name!);
    }
  }
}

