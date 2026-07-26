import 'package:flutter/foundation.dart';
import 'package:social_media_app/core/services/fcm_services.dart';
import 'package:social_media_app/core/utilities/supabase_constants.dart';
import '../../../core/supabase/supabase_provider.dart';

class GroupNotificationDispatcher {
  GroupNotificationDispatcher._();
  static final instance = GroupNotificationDispatcher._();

  final _fcm = FcmService.instance;

  Future<void> notifyMessage({
    required String groupId,
    required String groupName,
    required String senderId,
    required String senderName,
    required String senderAvatar,
    required String messageBody,
    required String messageType,
  }) async {
    await _dispatchToMembers(
      groupId: groupId,
      excludeUserId: senderId,
      payloadBuilder:
          (token) => _fcm.sendGroupNotification(
            receiverFcmToken: token,
            groupId: groupId,
            groupName: groupName,
            senderName: senderName,
            messageBody: messageBody,
            messageType: messageType,
            senderImageUrl: senderAvatar,
          ),
    );
  }

  Future<void> notifyMissedCall({
    required String groupId,
    required String callerId,
    required String callerName,
    required String callerAvatar,
    required String callId,
    required String callType,
  }) async {
    await _dispatchToMembers(
      groupId: groupId,
      excludeUserId: callerId,
      payloadBuilder:
          (token) => _fcm.sendCallNotification(
            receiverFcmToken: token,
            callerId: callerId,
            callerName: callerName,
            callerAvatar: callerAvatar,
            callId: callId,
            callType: callType,
          ),
    );
  }

  /// Rings every other member of the group when a group call starts.
  ///
  /// This was the missing piece behind "group call notifications never
  /// arrive when the app is terminated": GroupCallSignalingService.initiateCall()
  /// only wrote a row to `group_calls` and relied on Supabase Realtime to
  /// notify members, which requires an open socket and does nothing for a
  /// killed app. Call this from initiateCall() right after the call row is
  /// created so offline/terminated members actually get a push.
  Future<void> notifyIncomingCall({
    required String groupId,
    required String callId,
    required String groupName,
    required String groupAvatarUrl,
    required String callerId,
    required String callerName,
    required String callType,
    required String startedAt,
  }) async {
    await _dispatchToMembers(
      groupId: groupId,
      excludeUserId: callerId,
      payloadBuilder:
          (token) => _fcm.sendGroupCallNotification(
            receiverFcmToken: token,
            callId: callId,
            groupId: groupId,
            groupName: groupName,
            groupAvatarUrl: groupAvatarUrl,
            callerId: callerId,
            callerName: callerName,
            callType: callType,
            startedAt: startedAt,
          ),
    );
  }

  Future<void> _dispatchToMembers({
    required String groupId,
    required String excludeUserId,
    required Future<void> Function(String token) payloadBuilder,
  }) async {
    try {
      final rows = await SupabaseProvider.client
          .from(SupabaseConstants.groupMembers)
          .select(
            '${GroupMemberColumns.userId},'
            'users!${SupabaseConstants.groupMembers}'
            '_${GroupMemberColumns.userId}_fkey'
            '(${UserColumns.fcmToken})',
          )
          .eq(GroupMemberColumns.groupId, groupId)
          .neq(GroupMemberColumns.userId, excludeUserId);

      final futures = <Future<void>>[];

      for (final row in rows as List) {
        final userInfo = row['users'] as Map<String, dynamic>?;
        final token = userInfo?[UserColumns.fcmToken] as String?;
        if (token == null || token.isEmpty) continue;
        futures.add(payloadBuilder(token));
      }

      await Future.wait(futures, eagerError: false);
    } catch (e) {
      debugPrint('[GroupNotificationDispatcher] error: $e');
    }
  }
}
