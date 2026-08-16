import 'package:flutter/foundation.dart';
import 'package:social_media_app/core/services/fcm_services.dart';
import '../../../../core/supabase/supabase_provider.dart';
import 'chat_list_service.dart';

class ChatNotificationDispatcher {
  ChatNotificationDispatcher._();
  static final instance = ChatNotificationDispatcher._();

  final _fcm = FcmService.instance;
  final _supabase = SupabaseProvider.client;
  final _list = ChatListService();

  Future<void> notifyMessage({
    required String messageId,
    required String senderId,
    required String receiverId,
    required String senderName,
    required String senderImageUrl,
    required String messageBody,
    String messageType = 'text',
    String? attachmentUrl,
    String? caption,
    int? durationSeconds,
    String? fileName,
    int? fileSizeBytes,
    String? replyToMessageId,
    String? replyToText,
    String? replyToMessageType,
    String? replyToSenderId,
    String? replyToMediaUrl,
    String? replyToStoryId,
    String? replyToStoryAuthorId,
    String? replyToStoryType,
    String? replyToStoryMediaUrl,
    String? replyToStoryText,
    String? replyToStoryBgColor,
    int? replyToStoryDurationSeconds,
    String? forwardedFromUserId,
    String? forwardedFromUserName,
    String? forwardedFromUserAvatar,
  }) async {
    try {
      final muted =
          await _supabase.rpc(
                'is_chat_muted',
                params: {'p_owner': receiverId, 'p_peer': senderId},
              )
              as bool? ??
          false;
      if (muted) return;

      final receiverInfo = await _list.getReceiverPushInfo(receiverId);
      if (receiverInfo == null) {
        debugPrint('[ChatNotificationDispatcher] no FCM token — skipping');
        return;
      }

      await _fcm.sendChatNotification(
        messageId: messageId,
        receiverFcmToken: receiverInfo.fcmToken,
        senderId: senderId,
        senderName: senderName,
        senderImageUrl: senderImageUrl,
        messageBody: messageBody,
        messageType: messageType,
        attachmentUrl: attachmentUrl,
        caption: caption,
        durationSeconds: durationSeconds,
        fileName: fileName,
        fileSizeBytes: fileSizeBytes,
        replyToMessageId: replyToMessageId,
        replyToText: replyToText,
        replyToMessageType: replyToMessageType,
        replyToSenderId: replyToSenderId,
        replyToMediaUrl: replyToMediaUrl,
        replyToStoryId: replyToStoryId,
        replyToStoryAuthorId: replyToStoryAuthorId,
        replyToStoryType: replyToStoryType,
        replyToStoryMediaUrl: replyToStoryMediaUrl,
        replyToStoryText: replyToStoryText,
        replyToStoryBgColor: replyToStoryBgColor,
        replyToStoryDurationSeconds: replyToStoryDurationSeconds,
        forwardedFromUserId: forwardedFromUserId,
        forwardedFromUserName: forwardedFromUserName,
        forwardedFromUserAvatar: forwardedFromUserAvatar,
      );
    } catch (e) {
      debugPrint('[ChatNotificationDispatcher] error: $e');
    }
  }
}
