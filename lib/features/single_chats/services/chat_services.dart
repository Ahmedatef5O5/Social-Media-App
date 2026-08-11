import 'package:social_media_app/core/services/cloudinary_storage_services.dart';
import 'package:social_media_app/features/single_chats/models/message_model.dart';
import '../../../core/presence/model/chat_action_type.dart';
import '../../../core/services/network_status_service.dart';
import '../models/chat_block_status.dart';
import '../models/chat_user_model.dart';
import '../models/presence_snapshot.dart';
import 'chat_block_service.dart';
import 'chat_list_service.dart';
import 'chat_messages_service.dart';
import 'chat_presence_service.dart';
import 'chat_reactions_service.dart';
export 'chat_list_service.dart' show ReceiverPushInfo;

class ChatServices {
  final NetworkStatusService _networkStatus;

  ChatServices({NetworkStatusService? networkStatus})
    : _networkStatus = networkStatus ?? NetworkStatusService.instance;

  CloudinaryStorageServices get storage => CloudinaryStorageServices.instance;

  late final _list = ChatListService(networkStatus: _networkStatus);
  late final _messages = ChatMessagesService();
  late final _reactions = ChatReactionsService();
  late final _presence = ChatPresenceService();
  late final _block = ChatBlockService();

  // ── Chats list ──────────────────────────────────────────────────────────
  Future<ReceiverPushInfo?> getReceiverPushInfo(String receiverId) =>
      _list.getReceiverPushInfo(receiverId);

  Future<void> saveMyFcmToken(String userId, String token) =>
      _list.saveMyFcmToken(userId, token);

  Future<List<ChatUserModel>> getChatsList(String currentUserId) =>
      _list.getChatsList(currentUserId);

  Stream<void> getChatsStream(String currentUserId) =>
      _list.getChatsStream(currentUserId);

  // ── Messages ────────────────────────────────────────────────────────────
  Stream<List<MessageModel>> getMessagesStream({
    required String senderId,
    required String receiverId,
  }) => _messages.getMessagesStream(senderId: senderId, receiverId: receiverId);

  Future<List<Map<String, dynamic>>> getChatMedia(String receiverId) =>
      _messages.getChatMedia(receiverId);

  Future<List<MessageModel>> getMediaPreview({
    required String senderId,
    required String receiverId,
    int limit = 6,
  }) => _messages.getMediaPreview(
    senderId: senderId,
    receiverId: receiverId,
    limit: limit,
  );

  Future<List<MessageModel>> getMediaMessages({
    required String senderId,
    required String receiverId,
    required String messageType,
    int limit = 100,
  }) => _messages.getMediaMessages(
    senderId: senderId,
    receiverId: receiverId,
    messageType: messageType,
    limit: limit,
  );

  Future<List<MessageModel>> getLinkMessages({
    required String senderId,
    required String receiverId,
    int limit = 100,
  }) => _messages.getLinkMessages(
    senderId: senderId,
    receiverId: receiverId,
    limit: limit,
  );

  Future<void> upsertCallMessage({
    required String callId,
    required String senderId,
    required String receiverId,
    required String status,
    required String callType,
    String duration = '',
  }) => _messages.upsertCallMessage(
    callId: callId,
    senderId: senderId,
    receiverId: receiverId,
    status: status,
    callType: callType,
    duration: duration,
  );

  Future<String> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
    String messageType = 'text',
    String? imageUrl,
    String? videoUrl,
    String? voiceUrl,
    int? durationSeconds,
    String? fileUrl,
    String? fileName,
    int? fileSizeBytes,
    String? caption,
    String? replyToMessageId,
    String? replyToText,
    String? replyToMessageType,
    String? replyToSenderId,
    String? replyToMediaUrl,
    String? imagePublicId,
    String? videoPublicId,
    String? voicePublicId,
    String? filePublicId,
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
  }) => _messages.sendMessage(
    senderId: senderId,
    receiverId: receiverId,
    text: text,
    messageType: messageType,
    imageUrl: imageUrl,
    videoUrl: videoUrl,
    voiceUrl: voiceUrl,
    durationSeconds: durationSeconds,
    fileUrl: fileUrl,
    fileName: fileName,
    fileSizeBytes: fileSizeBytes,
    caption: caption,
    replyToMessageId: replyToMessageId,
    replyToText: replyToText,
    replyToMessageType: replyToMessageType,
    replyToSenderId: replyToSenderId,
    replyToMediaUrl: replyToMediaUrl,
    imagePublicId: imagePublicId,
    videoPublicId: videoPublicId,
    voicePublicId: voicePublicId,
    filePublicId: filePublicId,
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

  Future<void> editMessage({
    required String messageId,
    required String newText,
    required bool isCaptionEdit,
  }) => _messages.editMessage(
    messageId: messageId,
    newText: newText,
    isCaptionEdit: isCaptionEdit,
  );

  Future<void> deleteMessage({required String messageId}) =>
      _messages.deleteMessage(messageId: messageId);

  Future<void> deleteMessageForMe({
    required String messageId,
    required String currentUserId,
  }) => _messages.deleteMessageForMe(
    messageId: messageId,
    currentUserId: currentUserId,
  );

  Future<void> deleteMessagesForMe({
    required List<MessageModel> messages,
    required String currentUserId,
  }) => _messages.deleteMessagesForMe(
    messages: messages,
    currentUserId: currentUserId,
  );

  Future<void> deleteMessagesForEveryone(List<String> messageIds) =>
      _messages.deleteMessagesForEveryone(messageIds);

  Future<void> markMessagesAsRead({
    required String senderId,
    required String currentUserId,
  }) => _messages.markMessagesAsRead(
    senderId: senderId,
    currentUserId: currentUserId,
  );

  Future<Map<String, String?>> getCurrentUserInfo(String userId) =>
      _messages.getCurrentUserInfo(userId);

  // ── Reactions ───────────────────────────────────────────────────────────
  Future<void> toggleReaction({
    required String messageId,
    required String conversationId,
    required String emoji,
  }) => _reactions.toggleReaction(
    messageId: messageId,
    conversationId: conversationId,
    emoji: emoji,
  );

  Stream<List<Map<String, dynamic>>> getMessageReactionsStream(
    String conversationId,
  ) => _reactions.getMessageReactionsStream(conversationId);

  // ── Presence & typing ───────────────────────────────────────────────────

  Future<DateTime?> getUserLastSeen(String userId) =>
      _presence.getUserLastSeen(userId);

  Stream<DateTime?> getLastSeenStream(String userId) =>
      _presence.getLastSeenStream(userId);

  Stream<PresenceSnapshot> getPresenceStream(String userId) =>
      _presence.getPresenceStream(userId);

  Future<void> setTyping({
    required String chatId,
    required String currentUserId,
    required bool isTyping,
  }) => _presence.setTyping(
    chatId: chatId,
    currentUserId: currentUserId,
    isTyping: isTyping,
  );

  Stream<bool> getTypingStream({
    required String chatId,
    required String receiverId,
    required String currentUserId,
  }) => _presence.getTypingStream(
    chatId: chatId,
    receiverId: receiverId,
    currentUserId: currentUserId,
  );

  Stream<Map<String, ChatActionType>> getGlobalActionsStream(
    String currentUserId,
  ) => _presence.getGlobalActionsStream(currentUserId);

  // ── Block ───────────────────────────────────────────────────────────────
  Future<ChatBlockStatus> getBlockStatus({
    required String currentUserId,
    required String otherUserId,
  }) => _block.getBlockStatus(
    currentUserId: currentUserId,
    otherUserId: otherUserId,
  );

  Stream<ChatBlockStatus> watchBlockStatus({
    required String currentUserId,
    required String otherUserId,
  }) => _block.watchBlockStatus(
    currentUserId: currentUserId,
    otherUserId: otherUserId,
  );

  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
  }) => _block.blockUser(blockerId: blockerId, blockedId: blockedId);

  Future<void> unblockUser({
    required String blockerId,
    required String blockedId,
  }) => _block.unblockUser(blockerId: blockerId, blockedId: blockedId);
}
