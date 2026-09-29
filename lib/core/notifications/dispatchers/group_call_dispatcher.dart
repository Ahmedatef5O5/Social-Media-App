import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:social_media_app/core/notifications/channels/notification_channel_setup.dart';
import 'package:social_media_app/core/notifications/helpers/notification_app_state_helper.dart';
import 'package:social_media_app/core/notifications/helpers/notification_avatar_builder.dart';
import 'package:social_media_app/core/notifications/helpers/notification_id_helper.dart';
import 'package:social_media_app/core/notifications/notification_navigator_key.dart';
import 'package:social_media_app/core/services/incoming_call_navigation_guard.dart';
import 'package:social_media_app/core/supabase/supabase_provider.dart';
import 'package:social_media_app/features/group_calls/models/group_call_model.dart';
import 'package:social_media_app/features/group_calls/views/incoming_group_call_screen.dart';

class GroupCallDispatcher {
  GroupCallDispatcher._();
  static final GroupCallDispatcher instance = GroupCallDispatcher._();

  final NotificationAvatarBuilder _avatarBuilder = NotificationAvatarBuilder();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> showIncomingGroupCallNotification({
    required String callId,
    required String groupId,
    required String groupName,
    required String groupAvatarUrl,
    required String callerName,
    required String callType,
    String callerId = '',
  }) async {
    Uint8List profileBitmap;
    try {
      profileBitmap =
          await _avatarBuilder.fetchBitmap(groupAvatarUrl) ??
          await _avatarBuilder.buildLetterAvatar(groupName);
    } catch (_) {
      profileBitmap = await _avatarBuilder.defaultBitmap();
    }

    final subtitle =
        '$callerName is calling · ${callType == 'video' ? 'Group Video' : 'Group Voice'}';

    final androidDetails = AndroidNotificationDetails(
      NotificationChannelSetup.callChannel.id,
      NotificationChannelSetup.callChannel.name,
      channelDescription: NotificationChannelSetup.callChannel.description,
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.call,
      icon: '@drawable/ic_notification',
      largeIcon: ByteArrayAndroidBitmap(profileBitmap),
      fullScreenIntent: true,
      ongoing: true,
      autoCancel: false,
      timeoutAfter: 60000,
    );

    await _localNotifications.show(
      createNotificationId(callId),
      groupName,
      subtitle,
      NotificationDetails(android: androidDetails),
      payload:
          'group_call|$callId|$groupId|$groupName|$groupAvatarUrl|$callType|$callerId',
    );
  }

  Future<void> cancelIncomingGroupCallNotification(String callId) async {
    await _localNotifications.cancel(createNotificationId(callId));
  }

  Future<void> handleIncomingGroupCallData(Map<String, dynamic> data) async {
    var callerId =
        (data['callerId'] ??
                data['initiatorId'] ??
                data['initiator_id'] ??
                data['senderId'])
            as String? ??
        '';
    final currentUserId = SupabaseProvider.idOrNull;
    if (currentUserId == null) return;
    if (callerId.isNotEmpty && callerId == currentUserId) return;
    final callId = (data['callId'] ?? data['call_id']) as String? ?? '';
    final groupId = data['groupId'] as String? ?? '';
    final groupName = data['groupName'] as String? ?? 'Group';
    final groupAvatarUrl = data['groupAvatarUrl'] as String?;
    final callerName = data['callerName'] as String? ?? 'Unknown';
    final callType = data['callType'] as String? ?? 'audio';
    final startedAt = data['startedAt'] as String?;

    if (callerId.isEmpty) {
      if (callId.isEmpty) return;
      try {
        final row =
            await SupabaseProvider.client
                .from('group_calls')
                .select('initiator_id, status')
                .eq('call_id', callId)
                .maybeSingle();
        if (row == null) return;
        final initiatorId = row['initiator_id'] as String? ?? '';
        final status = row['status'] as String? ?? '';
        if (initiatorId.isEmpty || initiatorId == currentUserId) return;
        if (status != 'ringing') return;
        callerId = initiatorId;
      } catch (e) {
        debugPrint('[GroupCallDispatcher] initiator lookup failed: $e');
        return;
      }
    }

    if (IncomingCallNavigationGuard.shouldBlockIncomingGroupCall(
      callId: callId,
      initiatorId: callerId,
      currentUserId: currentUserId,
    )) {
      return;
    }

    if (!isAppInForeground()) {
      await showIncomingGroupCallNotification(
        callId: callId,
        groupId: groupId,
        groupName: groupName,
        groupAvatarUrl: groupAvatarUrl ?? '',
        callerName: callerName,
        callType: callType,
        callerId: callerId,
      );
    }

    final call = GroupCallModel(
      callId: callId,
      groupId: groupId,
      groupName: groupName,
      groupAvatarUrl: groupAvatarUrl,
      initiatorId: callerId,
      initiatorName: callerName,
      status: GroupCallStatus.ringing,
      type: callType == 'video' ? GroupCallType.video : GroupCallType.audio,
      startedAt:
          startedAt != null
              ? (DateTime.tryParse(startedAt) ?? DateTime.now())
              : DateTime.now(),
    );

    if (!IncomingCallNavigationGuard.claim(callId)) return;

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
}
