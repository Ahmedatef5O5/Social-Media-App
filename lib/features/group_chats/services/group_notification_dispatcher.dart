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
    required String groupImageUrl,
    required String senderId,
    required String senderName,
    required String senderAvatar,
    required String messageBody,
    required String messageType,
    List<String> mentionedUserIds = const [],
  }) async {
    await _dispatchToMembers(
      groupId: groupId,
      excludeUserId: senderId,
      payloadBuilder:
          (memberId, token) => _fcm.sendGroupNotification(
            receiverFcmToken: token,
            groupId: groupId,
            groupName: groupName,
            senderName: senderName,
            messageBody: messageBody,
            messageType: messageType,
            senderImageUrl: senderAvatar,
            groupImageUrl: groupImageUrl,
            isMention: mentionedUserIds.contains(memberId),
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
          (memberId, token) => _fcm.sendCallNotification(
            receiverFcmToken: token,
            callerId: callerId,
            callerName: callerName,
            callerAvatar: callerAvatar,
            callId: callId,
            callType: callType,
          ),
    );
  }

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
          (memberId, token) => _fcm.sendGroupCallNotification(
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
    required Future<void> Function(String memberId, String token)
    payloadBuilder,
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
        final memberId = row[GroupMemberColumns.userId] as String?;
        if (token == null || token.isEmpty || memberId == null) continue;
        futures.add(payloadBuilder(memberId, token));
      }
      await Future.wait(futures, eagerError: false);
    } catch (e) {
      debugPrint('[GroupNotificationDispatcher] error: $e');
    }
  }
}
