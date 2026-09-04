import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../group_chats/models/groupe_message_model.dart';
import '../../single_chats/services/chat_services.dart';
import '../../group_chats/services/group_chat_services.dart';
import '../models/forward_target_selection.dart';
import '../models/forwardable_message.dart';
import '../../../core/cache/services/local_snapshot_store.dart';
import '../../../core/helpers/chat_helper.dart';
import '../../../core/utilities/supabase_constants.dart';

/// Orchestrates the actual forward: for every selected message, creates a
/// brand-new message row for each selected target (person or group),
/// carrying the original payload plus forwarded_from_* metadata. Lives in
/// chat_forwarding (not single_chats or group_chats) because it depends on
/// both — a single Forward action can target people and groups at once.
class ForwardService {
  final ChatServices _chatServices;
  final GroupChatServices _groupChatServices;

  ForwardService({
    ChatServices? chatServices,
    GroupChatServices? groupChatServices,
  }) : _chatServices = chatServices ?? ChatServices(),
       _groupChatServices = groupChatServices ?? GroupChatServices();

  Future<void> forwardMessages({
    required List<ForwardableMessage> messages,
    required ForwardTargetSelection targets,
    required String currentUserId,
  }) async {
    final futures = <Future>[];

    for (final userId in targets.userIds) {
      futures.add(
        _forwardAllToSingleChat(
          currentUserId: currentUserId,
          receiverId: userId,
          messages: messages,
        ),
      );
    }

    for (final entry in targets.groups.entries) {
      futures.add(
        _forwardAllToGroupChat(
          groupId: entry.key,
          groupName: entry.value,
          messages: messages,
        ),
      );
    }

    await Future.wait(futures);
  }

  Future<void> _forwardAllToSingleChat({
    required String currentUserId,
    required String receiverId,
    required List<ForwardableMessage> messages,
  }) async {
    for (final message in messages) {
      await _forwardToSingleChat(
        currentUserId: currentUserId,
        receiverId: receiverId,
        message: message,
      );
    }
  }

  Future<void> _forwardAllToGroupChat({
    required String groupId,
    required String groupName,
    required List<ForwardableMessage> messages,
  }) async {
    for (final message in messages) {
      await _forwardToGroupChat(
        groupId: groupId,
        groupName: groupName,
        message: message,
      );
    }
  }

  Future<void> _forwardToSingleChat({
    required String currentUserId,
    required String receiverId,
    required ForwardableMessage message,
  }) async {
    final clientMessageId = const Uuid().v4();

    final sent = await _chatServices.sendMessage(
      senderId: currentUserId,
      receiverId: receiverId,
      text:
          message.messageType == 'file'
              ? (message.fileName ??
                  (message.text.isNotEmpty ? message.text : 'File'))
              : message.text,
      clientMessageId: clientMessageId,
      messageType: message.messageType,
      imageUrl: message.imageUrl,
      videoUrl: message.videoUrl,
      voiceUrl: message.voiceUrl,
      durationSeconds: message.durationSeconds,
      fileUrl: message.fileUrl,
      fileName: message.fileName,
      fileSizeBytes: message.fileSizeBytes,
      caption: message.caption,
      forwardedFromUserId: message.originalSenderId,
      forwardedFromUserName: message.originalSenderName,
      forwardedFromUserAvatar: message.originalSenderAvatar,
    );
    final newMessageId = sent.id;

    await _hydrateSingleChatShadow(
      messageId: newMessageId,
      clientMessageId: clientMessageId,
      currentUserId: currentUserId,
      receiverId: receiverId,
      message: message,
    );
  }

  Future<void> _forwardToGroupChat({
    required String groupId,
    required String groupName,
    required ForwardableMessage message,
  }) async {
    final result = await _groupChatServices.sendGroupMessage(
      groupId: groupId,
      clientMessageId: const Uuid().v4(),
      groupName: groupName,
      text:
          message.messageType == 'file'
              ? (message.fileName ??
                  (message.text.isNotEmpty ? message.text : 'File'))
              : message.text,
      messageType: message.messageType,
      imageUrl: message.imageUrl,
      videoUrl: message.videoUrl,
      voiceUrl: message.voiceUrl,
      durationSeconds: message.durationSeconds,
      fileUrl: message.fileUrl,
      fileName: message.fileName,
      fileSizeBytes: message.fileSizeBytes,
      caption: message.caption,
      forwardedFromUserId: message.originalSenderId,
      forwardedFromUserName: message.originalSenderName,
      forwardedFromUserAvatar: message.originalSenderAvatar,
    );

    await _hydrateGroupShadow(groupId: groupId, message: result.message);
  }

  Future<void> _hydrateSingleChatShadow({
    required String messageId,
    required String clientMessageId,
    required String currentUserId,
    required String receiverId,
    required ForwardableMessage message,
  }) async {
    try {
      final conversationId = ChatHelper.buildConversationId(
        currentUserId,
        receiverId,
      );
      final key = 'chat_messages_snapshot_$conversationId';

      final shadowMessage = {
        MessagesColumns.id: messageId,
        MessagesColumns.clientMessageId: clientMessageId,
        MessagesColumns.senderId: currentUserId,
        MessagesColumns.receiverId: receiverId,
        MessagesColumns.messageText: message.text,
        MessagesColumns.createdAt: DateTime.now().toIso8601String(),
        MessagesColumns.isRead: false,
        MessagesColumns.isEdited: false,
        MessagesColumns.messageType: message.messageType,
        MessagesColumns.imageUrl: message.imageUrl,
        MessagesColumns.videoUrl: message.videoUrl,
        MessagesColumns.voiceUrl: message.voiceUrl,
        MessagesColumns.durationSeconds: message.durationSeconds,
        MessagesColumns.fileName: message.fileName,
        MessagesColumns.fileSizeBytes: message.fileSizeBytes,
        MessagesColumns.caption: message.caption,
        MessagesColumns.replyToMessageId: null,
        MessagesColumns.replyToText: null,
        MessagesColumns.replyToMessageType: null,
        MessagesColumns.replyToSenderId: null,
        MessagesColumns.replyToMediaUrl: null,
        MessagesColumns.replyToStoryId: null,
        MessagesColumns.replyToStoryAuthorId: null,
        MessagesColumns.replyToStoryType: null,
        MessagesColumns.replyToStoryMediaUrl: null,
        MessagesColumns.replyToStoryText: null,
        MessagesColumns.replyToStoryBgColor: null,
        MessagesColumns.replyToStoryDurationSeconds: null,
        MessagesColumns.forwardedFromUserId: message.originalSenderId,
        MessagesColumns.forwardedFromUserName: message.originalSenderName,
        MessagesColumns.forwardedFromUserAvatar: message.originalSenderAvatar,
        'reactionsCreatedAt': const {},
        MessagesColumns.deletedFor: const <String>[],
      };

      final existing = LocalSnapshotStore.instance.readList(key);
      if (existing.any((m) => m['id'] == messageId)) return;

      await LocalSnapshotStore.instance.saveList(key, [
        shadowMessage,
        ...existing,
      ]);
    } catch (e) {
      debugPrint('⚠️ ForwardService single-chat shadow hydrate failed: $e');
    }
  }

  Future<void> _hydrateGroupShadow({
    required String groupId,
    required GroupMessageModel message,
  }) async {
    try {
      final key = 'group_messages_snapshot_$groupId';

      final shadowMessage = message.toCacheJson();

      final existing = LocalSnapshotStore.instance.readList(key);
      if (existing.any((m) => m['id'] == shadowMessage['id'])) return;

      await LocalSnapshotStore.instance.saveList(key, [
        shadowMessage,
        ...existing,
      ]);
    } catch (e) {
      debugPrint('⚠️ ForwardService group shadow hydrate failed: $e');
    }
  }
}
