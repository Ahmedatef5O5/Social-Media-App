import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/cloudinary_storage_services.dart';
import '../../../../core/services/fcm_services.dart';
import '../../../notifications/repository/notifications_repository.dart';
import '../../../single_chats/services/chat_services.dart';
import '../../model/story_model.dart';

part 'story_reply_state.dart';

class StoryReplyCubit extends Cubit<StoryReplyState> {
  final ChatServices _chatServices;

  StoryReplyCubit({ChatServices? chatServices})
    : _chatServices = chatServices ?? ChatServices(),
      super(StoryReplyIdle());

  final String currentUserId = Supabase.instance.client.auth.currentUser!.id;

  Future<void> sendReply({
    required StoryModel story,
    String text = '',
    File? mediaFile,
    String? mediaMessageType, 
  }) async {
    if (text.trim().isEmpty && mediaFile == null) return;

    if (story.authorId == currentUserId) return;

    emit(StoryReplySending());

    try {
      String? imageUrl, videoUrl, imagePublicId, videoPublicId;

      if (mediaFile != null) {
        final result = await CloudinaryStorageServices.instance.uploadFile(
          mediaFile,
          'chats',
          mediaMessageType == 'video' ? 'video' : 'image',
        );

        if (mediaMessageType == 'video') {
          videoUrl = result.secureUrl;
          videoPublicId = result.publicId;
        } else {
          imageUrl = result.secureUrl;
          imagePublicId = result.publicId;
        }
      }

      final resolvedMessageType = mediaFile != null ? mediaMessageType! : 'text';

      final String? storyPreviewText =
          story.storyType == StoryType.text ? story.contentText : story.caption;

      await _chatServices.sendMessage(
        senderId: currentUserId,
        receiverId: story.authorId,
        text: text,
        messageType: resolvedMessageType,
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        caption: mediaFile != null && text.isNotEmpty ? text : null,
        imagePublicId: imagePublicId,
        videoPublicId: videoPublicId,
        replyToStoryId: story.id,
        replyToStoryAuthorId: story.authorId,
        replyToStoryType: story.storyType.name,
        replyToStoryMediaUrl: story.imageUrl ?? story.videoUrl,
        replyToStoryText: storyPreviewText,
        replyToStoryBgColor: story.backgroundColor,
      );

      emit(StoryReplySent());

      unawaited(
        _notifyStoryAuthor(
          story: story,
          text: text,
          messageType: resolvedMessageType,
          mediaUrl: imageUrl ?? videoUrl,
        ),
      );
    } catch (e) {
      debugPrint('Error sending story reply: $e');
      emit(StoryReplyFailed(e.toString()));
    }
  }

  Future<void> _notifyStoryAuthor({
    required StoryModel story,
    required String text,
    required String messageType,
    String? mediaUrl,
  }) async {
    try {
      final me = await _chatServices.getCurrentUserInfo(currentUserId);
      final senderName = me['name'] ?? 'Someone';
      final senderImageUrl = me['imageUrl'] ?? '';
      final body =
          text.isNotEmpty
              ? text
              : (messageType == 'video' ? '🎥 Video' : '📷 Photo');

      await NotificationRepository.instance.notifyChatMessage(
        receiverId: story.authorId,
        senderId: currentUserId,
        senderName: senderName,
        senderImageUrl: senderImageUrl,
        messageBody: body,
        messageType: messageType,
        chatReferenceId: currentUserId,
      );

      final pushInfo = await _chatServices.getReceiverPushInfo(story.authorId);
      if (pushInfo == null) return;

      await FcmService.instance.sendChatNotification(
        receiverFcmToken: pushInfo.fcmToken,
        senderId: currentUserId,
        senderName: senderName,
        senderImageUrl: senderImageUrl,
        messageBody: body,
        messageType: messageType,
        attachmentUrl: mediaUrl,
      );
    } catch (e) {
      debugPrint('⚠️ story reply notification silent error: $e');
    }
  }

  void reset() => emit(StoryReplyIdle());
}