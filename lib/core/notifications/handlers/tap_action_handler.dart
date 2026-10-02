import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:social_media_app/core/helpers/content_deep_link_navigator.dart';
import 'package:social_media_app/core/notifications/dispatchers/call_notification_dispatcher.dart';
import 'package:social_media_app/core/notifications/dispatchers/group_call_dispatcher.dart';
import 'package:social_media_app/core/notifications/dispatchers/social_notification_dispatcher.dart';
import 'package:social_media_app/core/notifications/notification_navigator_key.dart';
import 'package:social_media_app/core/notifications/notification_plugin_bootstrap.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/core/services/incoming_call_navigation_guard.dart';
import 'package:social_media_app/core/supabase/supabase_provider.dart';
import 'package:social_media_app/core/toast/app_toast.dart';
import 'package:social_media_app/features/group_calls/models/group_call_model.dart';
import 'package:social_media_app/features/group_calls/views/incoming_group_call_screen.dart';
import 'package:social_media_app/features/group_chats/services/group_chat_services.dart';
import 'package:social_media_app/features/notifications/models/app_notification_model.dart';
import 'package:social_media_app/features/notifications/views/notification_view.dart';
import 'package:social_media_app/features/posts/views/post_details_view.dart';
import 'package:social_media_app/features/single_chats/models/chat_user_model.dart';
import 'package:social_media_app/features/stories/cubits/stories_cubit/stories_cubit.dart';
import 'package:social_media_app/features/stories/models/story_model.dart';
import '../../../features/group_chats/helpers/group_navigation.dart';

class TapActionHandler {
  TapActionHandler._();
  static final TapActionHandler instance = TapActionHandler._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // ── Cold-start navigation queue ────────────────────────────────────────
  //
  // When the app is launched from a call notification, the tap is delivered
  // while `SplashView` is still on screen. Anything pushed at that moment sits
  // on top of the splash route and is wiped out by the splash's
  // `pushNamedAndRemoveUntil(...)`. So call navigation is queued here and
  // flushed by `markAppReadyAndFlush()` once `HomeView` is the root route.
  bool _isAppReadyForNavigation = false;
  Future<void> Function()? _pendingColdStartAction;

  // Set very early in bootstrap (before the tap is processed) so `SplashView`
  // can skip its animation delay for a call launch.
  bool _coldStartCallLaunchDetected = false;
  NotificationResponse? _coldStartLaunchResponse;
  bool _coldStartLaunchInspected = false;

  // Dedupe: the plugin can report the launch tap through both
  // `onDidReceiveNotificationResponse` and `getNotificationAppLaunchDetails`.
  String? _lastCallTapKey;
  DateTime? _lastCallTapAt;

  bool get isAppReadyForNavigation => _isAppReadyForNavigation;

  /// `true` when the app was cold-started by a call notification and its
  /// screen has not been shown yet.
  bool get hasPendingCallLaunch =>
      _coldStartCallLaunchDetected || _pendingColdStartAction != null;

  /// Called by `SplashView` right after `HomeView` becomes the root route.
  /// Runs the queued call navigation ON TOP of it.
  void markAppReadyAndFlush() {
    _isAppReadyForNavigation = true;
    _coldStartCallLaunchDetected = false;

    final action = _pendingColdStartAction;
    _pendingColdStartAction = null;
    if (action == null) return;

    unawaited(
      action().catchError((Object e, StackTrace s) {
        debugPrint('[TapActionHandler] queued cold-start action failed: $e\n$s');
      }),
    );
  }

  /// Splash routed to onboarding / login: a queued call is meaningless there.
  void discardPendingLaunch() {
    _isAppReadyForNavigation = true;
    _coldStartCallLaunchDetected = false;
    _pendingColdStartAction = null;
  }

  /// Cheap, early probe (a single platform-channel call) used by bootstrap:
  /// tells us whether this process was started by tapping a call notification,
  /// so the splash can be skipped straight away.
  Future<void> detectColdStartLaunch() async {
    if (_coldStartLaunchInspected) return;
    _coldStartLaunchInspected = true;
    try {
      final details =
          await NotificationPluginBootstrap.plugin
              .getNotificationAppLaunchDetails();
      final response = details?.notificationResponse;
      if (details != null &&
          details.didNotificationLaunchApp &&
          response != null) {
        _coldStartLaunchResponse = response;
        if (_isCallPayload(response.payload)) {
          _coldStartCallLaunchDetected = true;
        }
      }
    } catch (e) {
      debugPrint('[TapActionHandler] launch details probe failed: $e');
    }
  }

  static bool _isCallPayload(String? payload) =>
      payload != null &&
      (payload.startsWith('call|') || payload.startsWith('group_call|'));

  void _runWhenReady(Future<void> Function() action) {
    if (_isAppReadyForNavigation) {
      unawaited(
        action().catchError((Object e, StackTrace s) {
          debugPrint('[TapActionHandler] call action failed: $e\n$s');
        }),
      );
      return;
    }
    // Latest tap wins: the user can only be looking at one call.
    _pendingColdStartAction = action;
  }

  bool _isDuplicateCallTap(String key) {
    final now = DateTime.now();
    final last = _lastCallTapAt;
    final isDuplicate =
        _lastCallTapKey == key &&
        last != null &&
        now.difference(last) < const Duration(seconds: 3);
    _lastCallTapKey = key;
    _lastCallTapAt = now;
    return isDuplicate;
  }

  void listenToNotificationOpenedApp() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final type = message.data['notificationType'] as String? ?? 'chat';
      if (type == 'incoming_call') {
        CallNotificationDispatcher.instance.handleIncomingCallData(
          message.data,
        );
      } else if (type == 'incoming_group_call') {
        GroupCallDispatcher.instance.handleIncomingGroupCallData(message.data);
      } else {
        _navigateFromMessage(message.data);
      }
    });
  }

  Future<void> handleTerminatedAppLaunch() async {
    // 1) Launched by tapping / accepting a LOCAL notification (the incoming
    //    call notification is built by `flutter_local_notifications` inside
    //    the FCM background isolate). In that case FCM has no "initial
    //    message" at all — the launch data lives in the local plugin.
    await detectColdStartLaunch();
    final launchResponse = _coldStartLaunchResponse;
    _coldStartLaunchResponse = null;
    if (launchResponse != null && _isCallPayload(launchResponse.payload)) {
      handleTap(launchResponse);
    }

    // 2) Launched by an FCM notification message (non-call pushes, or a call
    //    push that carried a `notification` block).
    final message = await _fcm.getInitialMessage();
    if (message == null) return;

    final type = message.data['notificationType'] as String? ?? 'chat';
    if (type == 'incoming_call' || type == 'incoming_group_call') {
      _coldStartCallLaunchDetected = true;
    }

    _runWhenReady(() async {
      if (type == 'incoming_call') {
        await CallNotificationDispatcher.instance.handleIncomingCallData(
          message.data,
        );
      } else if (type == 'incoming_group_call') {
        await GroupCallDispatcher.instance.handleIncomingGroupCallData(
          message.data,
        );
      } else {
        _navigateFromMessage(message.data);
      }
    });
  }

  static void handleTap(NotificationResponse response) {
    if (response.payload == null) return;
    final payload = response.payload!;

    if (payload.startsWith('message_react|')) {
      final parts = payload.split('|');
      if (parts.length >= 7) {
        final isGroup = parts[1] == 'true';
        if (isGroup) {
          _openGroupChat(parts[2], parts[3]);
        } else {
          final user = ChatUserModel(
            id: parts[4],
            name: parts[5],
            imageUrl: parts[6].isEmpty ? null : parts[6],
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            navigatorKey.currentState?.pushNamed(
              AppRoutes.chatDetailsViewRoute,
              arguments: user,
            );
          });
        }
      }
      return;
    }

    if (payload.startsWith('group_call|')) {
      _handleGroupCallTap(response, payload);
      return;
    }

    if (payload.startsWith('call|')) {
      _handleSingleCallTap(response, payload);
      return;
    }

    if (payload.startsWith('group|')) {
      final parts = payload.split('|');
      if (parts.length >= 3) {
        _navigateFromMessage({
          'notificationType': 'group_message',
          'groupId': parts[1],
          'groupName': parts[2],
        });
      }
      return;
    }

    if (payload.startsWith('social|')) {
      final parts = payload.split('|');
      if (parts.length >= 2) {
        _routeSocialEvent(
          type: parts[1],
          referenceId: parts.length > 2 ? parts[2] : '',
          commentContext: parts.length > 6 ? parts[6] : null,
        );
      }
      return;
    }

    final parts = payload.split('|');
    if (parts.length >= 2) {
      _navigateFromMessage({
        'senderId': parts[0],
        'senderName': parts[1],
        'senderImageUrl': parts.length > 2 ? parts[2] : null,
      });
    }
  }

  // ─────────────────────────── 1:1 incoming call ───────────────────────────

  static void _handleSingleCallTap(NotificationResponse response, String payload) {
    final parts = payload.split('|');
    if (parts.length < 6) return;

    final callId = parts[1];
    final actionId = response.actionId;

    // Decline works from any isolate (it only needs the network), so it is
    // never queued behind app readiness.
    if (actionId == 'decline_call') {
      unawaited(CallNotificationDispatcher.instance.rejectCallViaRest(callId));
      return;
    }

    final handler = TapActionHandler.instance;
    if (handler._isDuplicateCallTap('call|$callId|$actionId')) return;

    final autoAccept = actionId == 'accept_call';

    handler._runWhenReady(
      () => _openIncomingCall(
        callId: callId,
        callerId: parts[2],
        callerName: parts[3],
        callerAvatar: parts[4],
        callType: parts[5],
        autoAccept: autoAccept,
      ),
    );
  }

  static Future<void> _openIncomingCall({
    required String callId,
    required String callerId,
    required String callerName,
    required String callerAvatar,
    required String callType,
    required bool autoAccept,
  }) async {
    final dispatcher = CallNotificationDispatcher.instance;

    // Already busy with another call: the ring must not disturb it.
    if (IncomingCallNavigationGuard.isUserBusyWithAnotherCall(callId)) {
      unawaited(dispatcher.cancelCallNotification(callId));
      return;
    }

    // Verify the call is still ringing before showing anything.
    final verdict = await _verifySingleCall(callId);
    if (verdict == _CallVerdict.gone) {
      unawaited(dispatcher.cancelCallNotification(callId));
      AppToast.info('This call has already ended');
      return;
    }

    if (!IncomingCallNavigationGuard.claim(callId)) return;
    unawaited(dispatcher.cancelCallNotification(callId));

    if (autoAccept) {
      dispatcher.setPendingCallAction(
        callId,
        CallNotificationDispatcher.pendingActionAccept,
      );
    }

    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      IncomingCallNavigationGuard.release(callId);
      return;
    }

    unawaited(
      navigator
          .pushNamed(
            AppRoutes.incomingCallRoute,
            arguments: {
              'callId': callId,
              'callerId': callerId,
              'callerName': callerName,
              'callerAvatar': callerAvatar,
              'callType': callType,
            },
          )
          .then((_) => IncomingCallNavigationGuard.release(callId)),
    );
  }

  static Future<_CallVerdict> _verifySingleCall(String callId) async {
    if (callId.isEmpty) return _CallVerdict.unknown;
    try {
      final row =
          await SupabaseProvider.client
              .from('calls')
              .select('status, start_time')
              .eq('call_id', callId)
              .maybeSingle();
      if (row == null) return _CallVerdict.gone;

      final status = row['status'] as String? ?? '';
      if (status != 'ringing' && status != 'accepted') return _CallVerdict.gone;

      final start = DateTime.tryParse(row['start_time']?.toString() ?? '');
      if (start != null &&
          DateTime.now().toUtc().difference(start.toUtc()) >
              const Duration(seconds: 90)) {
        return _CallVerdict.gone;
      }
      return _CallVerdict.active;
    } catch (e) {
      debugPrint('[TapActionHandler] call verification failed: $e');
      // Fail open: a real call must still be answerable if the check fails.
      return _CallVerdict.unknown;
    }
  }

  // ───────────────────────────── group call ────────────────────────────────

  static void _handleGroupCallTap(NotificationResponse response, String payload) {
    final data = _GroupCallPayload.parse(payload);
    if (data == null) return;

    final actionId = response.actionId;

    if (actionId == 'decline_group_call') {
      // Cancels the notification (and with it the channel ringtone). There is
      // no per-user "declined" state in the database for group calls.
      unawaited(
        GroupCallDispatcher.instance.cancelIncomingGroupCallNotification(
          data.callId,
        ),
      );
      return;
    }

    final handler = TapActionHandler.instance;
    if (handler._isDuplicateCallTap('group_call|${data.callId}|$actionId')) {
      return;
    }

    handler._runWhenReady(
      () => _openIncomingGroupCall(
        data,
        autoAccept: actionId == 'accept_group_call',
      ),
    );
  }

  static Future<void> _openIncomingGroupCall(
    _GroupCallPayload data, {
    required bool autoAccept,
  }) async {
    final dispatcher = GroupCallDispatcher.instance;
    final currentUserId = SupabaseProvider.idOrNull;

    // Verify the call is still alive and pick up authoritative details.
    Map<String, dynamic>? row;
    try {
      row =
          await SupabaseProvider.client
              .from('group_calls')
              .select()
              .eq('call_id', data.callId)
              .maybeSingle();
    } catch (e) {
      debugPrint('[TapActionHandler] group call lookup failed: $e');
    }

    if (row != null) {
      final status = row['status'] as String? ?? '';
      const alive = {'ringing', 'accepted', 'ongoing'};
      if (!alive.contains(status)) {
        unawaited(dispatcher.cancelIncomingGroupCallNotification(data.callId));
        AppToast.info('This call has already ended');
        return;
      }
    } else if (data.callId.isNotEmpty) {
      // No row at all: the call was deleted / never existed.
      unawaited(dispatcher.cancelIncomingGroupCallNotification(data.callId));
      AppToast.info('This call has already ended');
      return;
    }

    final callerId =
        data.callerId.isNotEmpty
            ? data.callerId
            : (row?['initiator_id'] as String? ?? '');

    if (IncomingCallNavigationGuard.shouldBlockIncomingGroupCall(
      callId: data.callId,
      initiatorId: callerId,
      currentUserId: currentUserId,
    )) {
      unawaited(dispatcher.cancelIncomingGroupCallNotification(data.callId));
      return;
    }
    if (!IncomingCallNavigationGuard.claim(data.callId)) return;
    unawaited(dispatcher.cancelIncomingGroupCallNotification(data.callId));

    final type = (row?['type'] as String?) ?? data.callType;
    final call = GroupCallModel(
      callId: data.callId,
      groupId: data.groupId,
      groupName: data.groupName,
      groupAvatarUrl:
          data.groupAvatarUrl.isNotEmpty
              ? data.groupAvatarUrl
              : row?['group_avatar_url'] as String?,
      initiatorId: callerId,
      initiatorName:
          data.callerName.isNotEmpty
              ? data.callerName
              : (row?['initiator_name'] as String? ?? data.groupName),
      status: GroupCallStatus.ringing,
      type: type == 'video' ? GroupCallType.video : GroupCallType.audio,
      startedAt:
          data.startedAt ??
          DateTime.tryParse(row?['started_at']?.toString() ?? '') ??
          DateTime.now(),
    );

    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      IncomingCallNavigationGuard.release(data.callId);
      return;
    }

    unawaited(
      navigator
          .push(
            MaterialPageRoute(
              builder:
                  (_) => IncomingGroupCallScreen(
                    call: call,
                    autoAccept: autoAccept,
                  ),
            ),
          )
          .then((_) => IncomingCallNavigationGuard.release(data.callId)),
    );
  }

  static void _navigateFromMessage(Map<String, dynamic> data) {
    final notifType = data['notificationType'] as String? ?? 'chat';

    if (notifType == 'message_react') {
      final isGroup = data['isGroup'] == 'true';
      if (isGroup) {
        _openGroupChat(
          data['groupId'] as String? ?? '',
          data['groupName'] as String? ?? 'Group',
        );
      } else {
        final user = ChatUserModel(
          id: data['actorId'] ?? '',
          name: data['actorName'] ?? '',
          imageUrl: data['actorImageUrl'],
        );
        navigatorKey.currentState?.pushNamed(
          AppRoutes.chatDetailsViewRoute,
          arguments: user,
        );
      }
      return;
    }
    if (notifType == 'group_message') {
      _openGroupChat(
        data['groupId'] as String? ?? '',
        data['groupName'] as String? ?? 'Group',
      );
      return;
    }
    if (SocialNotificationDispatcher.isSocialType(notifType)) {
      _routeSocialEvent(
        type: notifType,
        referenceId: SocialNotificationDispatcher.resolveSocialReferenceId(
          data,
        ),
        commentContext: data['context'] as String?,
      );
      return;
    }

    final user = ChatUserModel(
      id: data['senderId'] ?? '',
      name: data['senderName'] ?? '',
      imageUrl: data['senderImageUrl'],
    );
    navigatorKey.currentState?.pushNamed(
      AppRoutes.chatDetailsViewRoute,
      arguments: user,
    );
  }

  static void _routeSocialEvent({
    required String type,
    required String referenceId,
    String? commentContext,
  }) {
    const postEngagementTypes = {
      'post_react',
      'post_comment',
      'post_reshare',
      'post_save',
      'comment_reply',
      'comment_react',
    };

    if (type == 'mention') {
      if (commentContext == 'story' && referenceId.isNotEmpty) {
        _openMentionedStory(referenceId);
      } else if (referenceId.isNotEmpty) {
        _openPostDetails(referenceId, PostDetailsActiveMode.comments);
      } else {
        _openNotificationsView();
      }
      return;
    }

    if (type == 'story_react' && referenceId.isNotEmpty) {
      _openMyStory(referenceId);
      return;
    }

    if (postEngagementTypes.contains(type) && referenceId.isNotEmpty) {
      _openPostDetails(referenceId, _activeModeForType(type));
      return;
    }
    if (type == 'friend_request') {
      _openNotificationsView(NotificationType.friendRequest);
      return;
    }

    if (type == 'follow') {
      _openNotificationsView(NotificationType.follow);
      return;
    }

    _openNotificationsView();
  }

  static PostDetailsActiveMode _activeModeForType(String type) {
    switch (type) {
      case 'post_react':
        return PostDetailsActiveMode.reactions;
      case 'post_comment':
      case 'comment_reply':
      case 'comment_react':
        return PostDetailsActiveMode.comments;
      case 'post_reshare':
      case 'post_save':
      default:
        return PostDetailsActiveMode.none;
    }
  }

  static Future<void> _openPostDetails(
    String postId, [
    PostDetailsActiveMode initialActiveMode = PostDetailsActiveMode.none,
  ]) {
    return ContentDeepLinkNavigator.openPost(postId, initialActiveMode);
  }

  static void _openNotificationsView([NotificationType? initialFilter]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => NotificationsView(initialFilter: initialFilter),
        ),
      );
    });
  }

  static Future<void> _openMyStory(String storyId) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    final storiesCubit = context.read<StoriesCubit>();

    try {
      await storiesCubit.fetchStories(isRefresh: true);
      final myUserId = SupabaseProvider.idOrNull;
      final myStories =
          storiesCubit.cachedStories
              .where((s) => s.authorId == myUserId)
              .toList();
      final storyIndex = myStories.indexWhere((s) => s.id == storyId);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          AppRoutes.homeRoute,
          (route) => false,
        );

        navigatorKey.currentState?.pushNamed(
          AppRoutes.myStoriesListViewRoute,
          arguments: {'storiesCubit': storiesCubit, 'myStories': myStories},
        );

        if (storyIndex == -1) {
          AppToast.warning('This story is no longer available');
        } else {
          navigatorKey.currentState?.pushNamed(
            AppRoutes.storyDisplayViewRoute,
            arguments: {
              'storiesCubit': storiesCubit,
              'allUserGroups': [myStories],
              'initialGroupIndex': 0,
              'initialStoryIndex': storyIndex,
            },
          );
        }
      });
    } catch (e) {
      debugPrint('Error opening story from notification: $e');
      AppToast.error('Failed to open story');
    }
  }

  static Future<void> _openMentionedStory(String storyId) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    final storiesCubit = context.read<StoriesCubit>();

    try {
      await storiesCubit.fetchStories(isRefresh: true);
      final match = storiesCubit.cachedStories.where((s) => s.id == storyId);
      final authorId = match.isNotEmpty ? match.first.authorId : null;
      final authorGroup =
          authorId == null
              ? <StoryModel>[]
              : storiesCubit.cachedStories
                  .where((s) => s.authorId == authorId)
                  .toList();
      final storyIndex = authorGroup.indexWhere((s) => s.id == storyId);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          AppRoutes.homeRoute,
          (route) => false,
        );

        if (storyIndex == -1) {
          AppToast.warning('This story is no longer available');
          return;
        }

        navigatorKey.currentState?.pushNamed(
          AppRoutes.storyDisplayViewRoute,
          arguments: {
            'storiesCubit': storiesCubit,
            'allUserGroups': [authorGroup],
            'initialGroupIndex': 0,
            'initialStoryIndex': storyIndex,
          },
        );
      });
    } catch (e) {
      debugPrint('Error opening mentioned story from notification: $e');
      AppToast.error('Failed to open story');
    }
  }

  static Future<void> _openGroupChat(String groupId, String groupName) async {
    if (groupId.isEmpty) {
      _openNotificationsView();
      return;
    }
    try {
      final groups = await GroupChatServices().getMyGroups();
      final matches = groups.where((g) => g.id == groupId);
      final group = matches.isNotEmpty ? matches.first : null;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (group == null) {
          AppToast.warning('This group is no longer available');
          return;
        }

        openGroupChat(
          group.id,
          () => navigatorKey.currentState?.pushNamed(
            AppRoutes.groupChatRoute,
            arguments: group,
          ),
        );
      });
    } catch (e) {
      debugPrint('Error opening group chat from notification: $e');
      AppToast.error('Failed to open group chat');
    }
  }
}

enum _CallVerdict { active, gone, unknown }

/// Parsed `group_call|...` notification payload.
///
/// Supported layouts (`|` separated):
///  * current (9): `callId|groupId|groupName|callerName|callType|startedAt|callerId|groupAvatarUrl`
///  * 7 with a timestamp in slot 6: `callId|groupId|groupName|callerName|callType|startedAt`
///  * legacy 6/7: `callId|groupId|groupName|groupAvatarUrl|callType[|callerId]`
///  * 5: `callId|groupId|groupName|callerName`
class _GroupCallPayload {
  final String callId;
  final String groupId;
  final String groupName;
  final String callerName;
  final String callType;
  final DateTime? startedAt;
  final String callerId;
  final String groupAvatarUrl;

  const _GroupCallPayload({
    required this.callId,
    required this.groupId,
    required this.groupName,
    required this.callerName,
    required this.callType,
    required this.startedAt,
    required this.callerId,
    required this.groupAvatarUrl,
  });

  static _GroupCallPayload? parse(String payload) {
    final parts = payload.split('|');
    if (parts.length < 5) return null;

    final callId = parts[1];
    final groupId = parts[2];
    final groupName = parts[3];

    if (parts.length >= 9) {
      return _GroupCallPayload(
        callId: callId,
        groupId: groupId,
        groupName: groupName,
        callerName: parts[4],
        callType: parts[5],
        startedAt: DateTime.tryParse(parts[6]),
        callerId: parts[7],
        groupAvatarUrl: parts[8],
      );
    }

    if (parts.length == 5) {
      return _GroupCallPayload(
        callId: callId,
        groupId: groupId,
        groupName: groupName,
        callerName: parts[4],
        callType: 'audio',
        startedAt: null,
        callerId: '',
        groupAvatarUrl: '',
      );
    }

    // 6 or 7 (or 8) parts. A parseable timestamp in slot 6 marks the
    // documented layout; otherwise it is the legacy one.
    final slot6 = parts.length >= 7 ? DateTime.tryParse(parts[6]) : null;
    if (slot6 != null) {
      return _GroupCallPayload(
        callId: callId,
        groupId: groupId,
        groupName: groupName,
        callerName: parts[4],
        callType: parts[5],
        startedAt: slot6,
        callerId: '',
        groupAvatarUrl: '',
      );
    }

    return _GroupCallPayload(
      callId: callId,
      groupId: groupId,
      groupName: groupName,
      callerName: '',
      callType: parts[5],
      startedAt: null,
      callerId: parts.length >= 7 ? parts[6] : '',
      groupAvatarUrl: parts[4],
    );
  }
}
