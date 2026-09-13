import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/cache/repository/media_cache_repository.dart';
import '../../../../core/helpers/safe_emit_mixin.dart';
import '../../../../core/services/cloudinary_storage_services.dart';
import '../../../../core/services/fcm_services.dart';
import '../../../../core/supabase/supabase_provider.dart';
import '../../../notifications/repository/notifications_repository.dart';
import '../../../single_chats/services/chat_services.dart';
import '../../models/story_model.dart';
part 'story_reply_state.dart';

class StoryReplyCubit extends Cubit<StoryReplyState>
    with SafeEmitMixin<StoryReplyState> {
  final ChatServices _chatServices;
  final MediaCacheRepository? _mediaCacheRepository;

  StoryReplyCubit({
    ChatServices? chatServices,
    MediaCacheRepository? mediaCacheRepository,
  }) : _chatServices = chatServices ?? ChatServices(),
       _mediaCacheRepository = mediaCacheRepository,
       super(StoryReplyIdle());

  final String currentUserId = SupabaseProvider.id;

  Future<void> sendReply({
    required StoryModel story,
    String text = '',
    File? mediaFile,
    String? mediaMessageType,
    String? remoteMediaUrl,
    int? fileSizeBytes,
    String? fileName,
  }) async {
    if (text.trim().isEmpty && mediaFile == null && remoteMediaUrl == null) {
      return;
    }

    if (story.authorId == currentUserId) return;

    emit(StoryReplySending());

    try {
      String? imageUrl, videoUrl, imagePublicId, videoPublicId;
      int? effectiveSize = fileSizeBytes;
      String? effectiveName = fileName;

      if (mediaFile != null) {
        effectiveSize ??= await mediaFile.length();
        effectiveName ??= mediaFile.path.split(Platform.pathSeparator).last;

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

        // Adopt local file into cache immediately for the sender
        if (_mediaCacheRepository != null) {
          final uploadedUrl = imageUrl ?? videoUrl;
          if (uploadedUrl != null) {
            await _mediaCacheRepository.adoptUploadedFile(
              uploadedUrl,
              mediaFile,
            );
          }
        }
      } else if (remoteMediaUrl != null) {
        imageUrl = remoteMediaUrl;
      }

      final resolvedMessageType =
          mediaFile != null
              ? mediaMessageType!
              : (remoteMediaUrl != null ? mediaMessageType! : 'text');

      final String? storyPreviewText =
          story.storyType == StoryType.text ? story.contentText : story.caption;

      await _chatServices.sendMessage(
        senderId: currentUserId,
        receiverId: story.authorId,
        text: text,
        clientMessageId: const Uuid().v4(),
        messageType: resolvedMessageType,
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        fileSizeBytes: effectiveSize,
        fileName: effectiveName,
        caption:
            (mediaFile != null || remoteMediaUrl != null) && text.isNotEmpty
                ? text
                : null,
        imagePublicId: imagePublicId,
        videoPublicId: videoPublicId,
        replyToStoryId: story.id,
        replyToStoryAuthorId: story.authorId,
        replyToStoryType: story.storyType.name,
        replyToStoryMediaUrl: story.imageUrl ?? story.videoUrl,
        replyToStoryText: storyPreviewText,
        replyToStoryBgColor: story.backgroundColor,
        replyToStoryDurationSeconds:
            story.storyType == StoryType.video
                ? story.videoDurationSeconds
                : null,
      );

      emit(StoryReplySent());

      unawaited(
        _notifyStoryAuthor(
          story: story,
          text: text,
          messageType: resolvedMessageType,
          mediaUrl: imageUrl ?? videoUrl,
          fileName: effectiveName,
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
    String? fileName,
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
        fileName: fileName,
      );

      final pushInfo = await _chatServices.getReceiverPushInfo(story.authorId);
      if (pushInfo == null) return;

      final String? storyPreviewText =
          story.storyType == StoryType.text ? story.contentText : story.caption;

      await FcmService.instance.sendStoryReplyNotification(
        receiverFcmToken: pushInfo.fcmToken,
        senderId: currentUserId,
        senderName: senderName,
        senderImageUrl: senderImageUrl,
        messageBody: body,
        messageType: messageType,
        attachmentUrl: mediaUrl,
        replyToStoryId: story.id,
        replyToStoryType: story.storyType.name,
        replyToStoryMediaUrl: story.imageUrl ?? story.videoUrl,
        replyToStoryText: storyPreviewText,
        replyToStoryBgColor: story.backgroundColor,
      );
    } catch (e) {
      debugPrint('⚠️ story reply notification silent error: $e');
    }
  }

  void reset() => emit(StoryReplyIdle());
}
