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
    final message = await _fcm.getInitialMessage();
    if (message != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final type = message.data['notificationType'] as String? ?? 'chat';
        if (type == 'incoming_call') {
          CallNotificationDispatcher.instance.handleIncomingCallData(
            message.data,
          );
        } else if (type == 'incoming_group_call') {
          GroupCallDispatcher.instance.handleIncomingGroupCallData(
            message.data,
          );
        } else {
          _navigateFromMessage(message.data);
        }
      });
    }
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
      final parts = payload.split('|');
      if (parts.length >= 6) {
        final callId = parts[1];
        if (!IncomingCallNavigationGuard.claim(callId)) return;
        unawaited(
          CallNotificationDispatcher.instance.cancelCallNotification(callId),
        );

        final call = GroupCallModel(
          callId: parts[1],
          groupId: parts[2],
          groupName: parts[3],
          groupAvatarUrl: parts[4],
          initiatorId: '',
          initiatorName: parts[3],
          status: GroupCallStatus.ringing,
          type: parts[5] == 'video' ? GroupCallType.video : GroupCallType.audio,
          startedAt: DateTime.now(),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigatorKey.currentState
              ?.push(
                MaterialPageRoute(
                  builder: (_) => IncomingGroupCallScreen(call: call),
                ),
              )
              .then((_) => IncomingCallNavigationGuard.release(callId));
        });
      }
      return;
    }

    if (payload.startsWith('call|')) {
      final parts = payload.split('|');
      if (parts.length >= 6) {
        final callId = parts[1];
        if (response.actionId == 'decline_call') {
          CallNotificationDispatcher.instance.rejectCallViaRest(callId);
          return;
        }
        if (!IncomingCallNavigationGuard.claim(callId)) return;
        unawaited(
          CallNotificationDispatcher.instance.cancelCallNotification(callId),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigatorKey.currentState
              ?.pushNamed(
                AppRoutes.incomingCallRoute,
                arguments: {
                  'callId': callId,
                  'callerId': parts[2],
                  'callerName': parts[3],
                  'callerAvatar': parts[4],
                  'callType': parts[5],
                },
              )
              .then((_) => IncomingCallNavigationGuard.release(callId));
        });
      }
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
