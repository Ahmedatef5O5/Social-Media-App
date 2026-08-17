import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../../../core/audio/voice_recorder/services/audio_compression_service.dart';
import '../../../../core/cache/repository/media_cache_repository.dart';
import '../../../../core/cache/services/messages_snapshot_cache.dart';
import '../../../../core/chat_shared/controllers/chat_search_controller.dart';
import '../../../../core/connectivity/services/connectivity_banner_controller.dart';
import '../../../../core/helpers/chat_helper.dart';
import '../../../../core/helpers/selected_message_star_controller.dart';
import '../../../../core/presence/model/chat_action_type.dart';
import '../../../../core/services/fcm_services.dart';
import '../../../../core/services/supabase_storage_services.dart';
import '../../../../core/supabase/supabase_provider.dart';
import '../../../../core/utilities/supabase_constants.dart';
import '../../../notifications/repository/notifications_repository.dart';
import '../../../settings/repository/settings_repository.dart';
import '../../helper/chat_clear_store.dart';
import '../../models/chat_block_status.dart';
import '../../models/message_model.dart';
import '../../services/chat_permission_service.dart';
import '../../services/chat_presence_service.dart';
import '../../services/chat_services.dart';
import '../../widgets/chat_bubble.dart';
part 'chat_details_state.dart';
part 'chat_reactions_mixin.dart';
part 'chat_selection_mixin.dart';
part 'chat_presence_action_mixin.dart';

class ChatDetailsCubit extends Cubit<ChatDetailsState>
    with ChatReactionsMixin, ChatSelectionMixin, ChatPresenceActionMixin {
  @override
  final ChatServices _chatServices;
  @override
  final ChatPresenceService _presenceService;
  final MediaCacheRepository _mediaCacheRepository;
  final ChatPermissionService _chatPermissionService;
  final AudioCompressionService _audioCompressionService;
  final String receiverName;
  final String? senderImageUrl;

  static final _snapshotCache = MessagesSnapshotCache<MessageModel>(
    toCacheJson: (m) => m.toCacheJson(),
    fromJson: MessageModel.fromJson,
  );

  final ValueNotifier<ChatPermissionResult> chatPermission = ValueNotifier(
    const ChatPermissionResult(permission: ChatPermission.allowed),
  );

  final ValueNotifier<ChatBlockStatus> blockStatus = ValueNotifier(
    const ChatBlockStatus(),
  );
  StreamSubscription<ChatBlockStatus>? _blockStatusSubscription;

  final ValueNotifier<MessageModel?> replyToMessage =
      ValueNotifier<MessageModel?>(null);

  StreamSubscription? _messageSubscription;
  bool _hasReceivedFirstStreamEvent = false;
  bool get hasConfirmedInitialLoad => _hasReceivedFirstStreamEvent;

  @override
  List<MessageModel> cachedMessages = [];
  @override
  String? _messagesSnapshotKey;

  @override
  final currentUserId = SupabaseProvider.id;

  final String currentUserName;

  final Map<String, GlobalKey<ChatBubbleState>> bubbleKeys = {};

  late final ChatSearchController<MessageModel> searchController =
      ChatSearchController<MessageModel>(
        getMessages: () => cachedMessages,
        getSearchableText:
            (m) => (m.caption?.isNotEmpty == true ? m.caption! : m.text),
        getId: (m) => m.id,
      );

  ChatDetailsCubit(
    this._chatServices,
    this.receiverName,
    this._mediaCacheRepository, {
    this.senderImageUrl,
    this.currentUserName = 'Someone',
    ChatPermissionService? chatPermissionService,
    AudioCompressionService? audioCompressionService,
    required ChatPresenceService presenceService,
  }) : _presenceService = presenceService,
       _chatPermissionService =
           chatPermissionService ?? ChatPermissionService(),
       _audioCompressionService =
           audioCompressionService ?? AudioCompressionService(),
       super(ChatDetailsInitial());

  Future<void> resolveChatPermission(String receiverId) async {
    try {
      chatPermission.value = await _chatPermissionService.resolve(
        currentUserId: currentUserId,
        otherUserId: receiverId,
      );
    } catch (e) {
      debugPrint('resolveChatPermission error: $e');
    }
  }

  void watchBlockStatus(String receiverId) {
    final cached = ChatBlockStatusCache.instance.read(receiverId);
    if (cached != null) {
      blockStatus.value = cached;
    }

    _blockStatusSubscription?.cancel();
    _blockStatusSubscription = _chatServices
        .watchBlockStatus(currentUserId: currentUserId, otherUserId: receiverId)
        .listen((status) {
          blockStatus.value = status;
          unawaited(ChatBlockStatusCache.instance.write(receiverId, status));
        }, onError: (e) => debugPrint('watchBlockStatus error: $e'));
  }

  Future<void> toggleBlock({
    required String receiverId,
    required String otherUserName,
  }) async {
    try {
      if (blockStatus.value.blockedByMe) {
        await _chatServices.unblockUser(
          blockerId: currentUserId,
          blockedId: receiverId,
        );
      } else {
        await _chatServices.blockUser(
          blockerId: currentUserId,
          blockedId: receiverId,
        );
      }

      blockStatus.value = blockStatus.value.copyWith(
        blockedByMe: !blockStatus.value.blockedByMe,
        isLoaded: true,
      );
      unawaited(
        ChatBlockStatusCache.instance.write(receiverId, blockStatus.value),
      );
    } catch (e) {
      debugPrint('toggleBlock error: $e');
    }
  }

  Future<void> _ensureAllowedToSend(String receiverId) async {
    final current = chatPermission.value;
    switch (current.permission) {
      case ChatPermission.allowed:
        return;
      case ChatPermission.needsRequest:
        try {
          final requestId = await _chatPermissionService.createRequest(
            senderId: currentUserId,
            receiverId: receiverId,
          );
          chatPermission.value = ChatPermissionResult(
            permission: ChatPermission.allowed,
            messageRequestId: requestId,
          );
        } catch (e) {
          debugPrint('createRequest error: $e');
        }
        return;
      case ChatPermission.awaitingMyResponse:
        final requestId = current.messageRequestId;
        if (requestId != null) {
          try {
            await _chatPermissionService.acceptRequest(requestId);
          } catch (e) {
            debugPrint('acceptRequest error: $e');
          }
        }
        chatPermission.value = ChatPermissionResult(
          permission: ChatPermission.allowed,
          messageRequestId: requestId,
        );
        return;
    }
  }

  Future<void> declineMessageRequest() async {
    final requestId = chatPermission.value.messageRequestId;
    if (requestId == null) return;
    try {
      await _chatPermissionService.declineRequest(requestId);
    } catch (e) {
      debugPrint('declineRequest error: $e');
    }
  }

  @override
  final ValueNotifier<bool> isAtBottomNotifier = ValueNotifier<bool>(true);
  bool get isUserAtBottom => isAtBottomNotifier.value;

  List<MessageModel> _pendingMessagesSnapshot = [];
  final ValueNotifier<int> pendingNewCountNotifier = ValueNotifier<int>(0);
  bool get hasPendingMessages => pendingNewCountNotifier.value > 0;
  void setUserAtBottom(bool isAtBottom) {
    isAtBottomNotifier.value = isAtBottom;
  }

  void getMessagesStream({required String receiverId}) {
    _messageSubscription?.cancel();
    _hasReceivedFirstStreamEvent = false;

    final conversationId = ChatHelper.buildConversationId(
      currentUserId,
      receiverId,
    );
    _messagesSnapshotKey = 'chat_messages_snapshot_$conversationId';

    final diskMessages = _readMessagesSnapshot(_messagesSnapshotKey!);
    if (diskMessages.isNotEmpty) {
      for (var m in diskMessages) {
        if (m.reactions.isNotEmpty) {
          _reactionsCache[m.id] = Map<String, String>.from(m.reactions);
        }
      }

      final enrichedDiskMessages =
          diskMessages.map((m) {
            final reactions = _reactionsCache[m.id] ?? m.reactions;
            return m.copyWith(reactions: reactions);
          }).toList();

      cachedMessages = enrichedDiskMessages;

      _registerBubbleKeys(enrichedDiskMessages);

      emit(MessagesSuccessLoaded(messages: enrichedDiskMessages));
    }

    _listenReactions(conversationId);

    _messageSubscription = _chatServices
        .getMessagesStream(senderId: currentUserId, receiverId: receiverId)
        .listen(
          (rawMessages) {
            final clearedAt = ChatClearStore.instance.clearedAtFor(receiverId);
            final messages =
                clearedAt == null
                    ? rawMessages
                    : rawMessages
                        .where((m) => m.createdAt.isAfter(clearedAt))
                        .toList();

            final enriched =
                messages.map((m) {
                  final reactions = _reactionsCache[m.id] ?? {};
                  return m.copyWith(reactions: reactions);
                }).toList();

            List<MessageModel> resolved;
            if (!_hasReceivedFirstStreamEvent && cachedMessages.isNotEmpty) {
              final cachedIds = cachedMessages.map((m) => m.id).toSet();
              resolved = [
                ...enriched.where((m) => !cachedIds.contains(m.id)),
                ...cachedMessages,
              ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            } else {
              resolved = enriched;
            }
            _hasReceivedFirstStreamEvent = true;

            final existingIds = cachedMessages.map((m) => m.id).toSet();
            final newIds = resolved
                .map((m) => m.id)
                .toSet()
                .difference(existingIds);

            final bool hasOwnNewMessage = resolved.any(
              (m) => newIds.contains(m.id) && m.senderId == currentUserId,
            );
            final int otherNewCount =
                resolved
                    .where(
                      (m) =>
                          newIds.contains(m.id) && m.senderId != currentUserId,
                    )
                    .length;

            if (!isAtBottomNotifier.value &&
                otherNewCount > 0 &&
                !hasOwnNewMessage) {
              _pendingMessagesSnapshot = resolved;
              pendingNewCountNotifier.value = otherNewCount;
              _persistMessagesSnapshot(_messagesSnapshotKey!, resolved);
              return;
            }

            final currentIds = resolved.map((m) => m.id).toSet();
            bubbleKeys.removeWhere((key, _) => !currentIds.contains(key));
            _registerBubbleKeys(resolved);

            cachedMessages = resolved;
            _pendingMessagesSnapshot = [];
            pendingNewCountNotifier.value = 0;
            emit(MessagesSuccessLoaded(messages: resolved));

            _persistMessagesSnapshot(_messagesSnapshotKey!, resolved);
          },
          onError: (e) {
            debugPrint('Messages stream error: $e');
          },
        );
  }

  void flushPendingMessages() {
    if (_pendingMessagesSnapshot.isEmpty) return;
    final currentIds = _pendingMessagesSnapshot.map((m) => m.id).toSet();
    bubbleKeys.removeWhere((key, _) => !currentIds.contains(key));
    _registerBubbleKeys(_pendingMessagesSnapshot);
    cachedMessages = _pendingMessagesSnapshot;
    _pendingMessagesSnapshot = [];
    pendingNewCountNotifier.value = 0;
    emit(MessagesSuccessLoaded(messages: cachedMessages));
  }

  void _registerBubbleKeys(List<MessageModel> messages) {
    final currentIds = messages.map((m) => m.id).toSet();
    bubbleKeys.removeWhere((key, _) => !currentIds.contains(key));
    for (final msg in messages) {
      bubbleKeys.putIfAbsent(msg.id, () => GlobalKey<ChatBubbleState>());
    }
  }

  @override
  void _persistMessagesSnapshot(String key, List<MessageModel> messages) {
    _snapshotCache.persist(key, messages);
  }

  List<MessageModel> _readMessagesSnapshot(String key) {
    return _snapshotCache.read(key);
  }

  Future<void> markAsRead({required String senderId}) async {
    if (!SettingsRepository.instance.readReceipts) return;
    try {
      await _chatServices.markMessagesAsRead(
        senderId: senderId,
        currentUserId: currentUserId,
      );
    } catch (e) {
      debugPrint('error marking as read: $e');
      emit(MessagesError(e.toString()));
    }
  }

  final Map<String, double> uploadProgressMap = {};
  final Map<String, ValueNotifier<double>> uploadProgressNotifiers = {};

  ValueNotifier<double> progressNotifierFor(String messageId) {
    return uploadProgressNotifiers.putIfAbsent(
      messageId,
      () => ValueNotifier<double>(0),
    );
  }

  void _disposeProgressNotifier(String messageId) {
    uploadProgressNotifiers.remove(messageId)?.dispose();
  }

  Future<void> sendMessage({
    required String receiverId,
    required String messageText,
    String messageType = 'text',
    File? imageFile,
    File? videoFile,
    File? voiceFile,
    int? durationSeconds,
    File? documentFile,
    String? fileName,
    int? fileSizeBytes,
    String? remoteImageUrl,
    String? caption,
    MessageModel? replyTo,
    String? forwardedFromUserId,
    String? forwardedFromUserName,
    String? forwardedFromUserAvatar,
  }) async {
    if (blockStatus.value.isBlocked) return;

    if (messageText.trim().isEmpty &&
        imageFile == null &&
        videoFile == null &&
        voiceFile == null &&
        documentFile == null &&
        remoteImageUrl == null) {
      return;
    }
    await _ensureAllowedToSend(receiverId);

    final List<MessageModel> currentMessages = List.from(cachedMessages);

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMessage = MessageModel(
      id: tempId,
      senderId: currentUserId,
      receiverId: receiverId,
      text: messageText,
      messageType: messageType,
      createdAt: DateTime.now(),
      isRead: false,
      imageUrl: remoteImageUrl ?? imageFile?.path,
      videoUrl: videoFile?.path,
      voiceUrl: voiceFile?.path,
      durationSeconds: durationSeconds,
      caption: caption,
      fileName: fileName,
      fileUrl: documentFile?.path,
      fileSizeBytes: fileSizeBytes,
      replyToMessageId: replyTo?.id,
      replyToText:
          (replyTo?.text != null && replyTo!.text.isNotEmpty)
              ? replyTo.text
              : replyTo?.caption,
      replyToMessageType: replyTo?.messageType,
      replyToSenderId: replyTo?.senderId,
      replyToMediaUrl: MessageModel.replyMediaUrlFrom(replyTo),
      forwardedFromUserId: forwardedFromUserId,
      forwardedFromUserName: forwardedFromUserName,
      forwardedFromUserAvatar: forwardedFromUserAvatar,
      replyToStoryId: replyTo?.replyToStoryId,
      replyToStoryAuthorId: replyTo?.replyToStoryAuthorId,
      replyToStoryType: replyTo?.replyToStoryType,
      replyToStoryMediaUrl: replyTo?.replyToStoryMediaUrl,
      replyToStoryText: replyTo?.replyToStoryText,
      replyToStoryBgColor: replyTo?.replyToStoryBgColor,
      replyToStoryDurationSeconds: replyTo?.replyToStoryDurationSeconds,
    );

    final updatedMessages = [optimisticMessage, ...currentMessages];
    cachedMessages = updatedMessages;
    emit(MessagesSending(messages: updatedMessages));

    final cancelToken = dio_pkg.CancelToken();
    _cancelTokens[tempId] = cancelToken;
    try {
      String? imageUrl, videoUrl, voiceUrl, fileUrl;
      String? imagePublicId, videoPublicId, voicePublicId, filePublicId;

      if (remoteImageUrl != null) {
        imageUrl = remoteImageUrl;
      } else if (imageFile != null) {
        if (await imageFile.exists()) {
          uploadProgressMap[tempId] = 0.0;
          emit(MessagesSending(messages: updatedMessages));

          final result = await _chatServices.storage.uploadFile(
            imageFile,
            'chats',
            'image',
            cancelToken: cancelToken,
            onProgress: (progress) {
              uploadProgressMap[tempId] = progress;
              progressNotifierFor(tempId).value = progress;
            },
          );
          imageUrl = result.secureUrl;
          imagePublicId = result.publicId;
          await _mediaCacheRepository.adoptUploadedFile(imageUrl, imageFile);
          uploadProgressMap[tempId] = 1.0;
          emit(MessagesSending(messages: updatedMessages));
          await Future.delayed(const Duration(milliseconds: 200));
          uploadProgressMap.remove(tempId);
          _disposeProgressNotifier(tempId);
        } else {
          emit(
            MessagesError("Image file not found. Please try picking it again."),
          );
          emit(MessagesSuccessLoaded(messages: currentMessages));
        }
      }

      if (videoFile != null) {
        if (await videoFile.exists()) {
          uploadProgressMap[tempId] = 0.0;
          emit(MessagesSending(messages: updatedMessages));
          final result = await _chatServices.storage.uploadFile(
            videoFile,
            'chats',
            'video',
            cancelToken: cancelToken,
            onProgress: (progress) {
              uploadProgressMap[tempId] = progress;
              progressNotifierFor(tempId).value = progress;
            },
          );
          videoUrl = result.secureUrl;
          videoPublicId = result.publicId;
          await _mediaCacheRepository.adoptUploadedFile(videoUrl, videoFile);

          uploadProgressMap[tempId] = 1.0;
          emit(MessagesSending(messages: updatedMessages));
          await Future.delayed(const Duration(milliseconds: 200));
          uploadProgressMap.remove(tempId);
          _disposeProgressNotifier(tempId);
        } else {
          emit(MessagesError("Video file not found. Please try again."));
          emit(MessagesSuccessLoaded(messages: currentMessages));
          return;
        }
      }

      if (voiceFile != null) {
        if (await voiceFile.exists()) {
          uploadProgressMap[tempId] = 0.0;
          emit(MessagesSending(messages: updatedMessages));

          final compression = await _audioCompressionService.compress(
            voiceFile,
          );
          try {
            final result = await _chatServices.storage.uploadFile(
              compression.fileToUpload,
              'chats',
              'voice',
              cancelToken: cancelToken,
              onProgress: (progress) {
                uploadProgressMap[tempId] = progress;
                progressNotifierFor(tempId).value = progress;
              },
            );
            voiceUrl = result.secureUrl;
            voicePublicId = result.publicId;
            uploadProgressMap.remove(tempId);
            _disposeProgressNotifier(tempId);
          } finally {
            await _audioCompressionService.cleanup(compression);
          }
        } else {
          emit(MessagesError("Voice file not found."));
          return;
        }
      }

      if (documentFile != null) {
        if (await documentFile.exists()) {
          final result = await _chatServices.storage.uploadFile(
            documentFile,
            'chats',
            'file',
            cancelToken: cancelToken,
            onProgress: (progress) {
              uploadProgressMap[tempId] = progress;
              progressNotifierFor(tempId).value = progress;
            },
          );
          fileUrl = result.secureUrl;
          filePublicId = result.publicId;
          await _mediaCacheRepository.adoptUploadedFile(fileUrl, documentFile);
          uploadProgressMap[tempId] = 1.0;
          emit(MessagesSending(messages: updatedMessages));
          await Future.delayed(const Duration(milliseconds: 200));
          uploadProgressMap.remove(tempId);
          _disposeProgressNotifier(tempId);
        } else {
          emit(MessagesError("File not found. Please try picking it again."));
          emit(MessagesSuccessLoaded(messages: currentMessages));
          return;
        }
      }

      final newMessageId = await _chatServices.sendMessage(
        senderId: currentUserId,
        receiverId: receiverId,
        text: messageText,
        messageType: messageType,
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        voiceUrl: voiceUrl,
        durationSeconds: durationSeconds,
        fileUrl: fileUrl,
        fileName: fileName,
        fileSizeBytes: fileSizeBytes,
        caption: caption,
        replyToMessageId: replyTo?.id,
        replyToText:
            (replyTo?.text != null && replyTo!.text.isNotEmpty)
                ? replyTo.text
                : replyTo?.caption,
        replyToMessageType: replyTo?.messageType,
        replyToSenderId: replyTo?.senderId,
        replyToMediaUrl: MessageModel.replyMediaUrlFrom(replyTo),

        imagePublicId: imagePublicId,
        videoPublicId: videoPublicId,
        voicePublicId: voicePublicId,
        filePublicId: filePublicId,
        forwardedFromUserId: forwardedFromUserId,
        forwardedFromUserName: forwardedFromUserName,
        forwardedFromUserAvatar: forwardedFromUserAvatar,
      );

      final index = cachedMessages.indexWhere((m) => m.id == tempId);
      if (index != -1) {
        cachedMessages[index] = cachedMessages[index].copyWith(
          id: newMessageId,
        );
      }

      if (messageType != 'call') {
        await NotificationRepository.instance.notifyChatMessage(
          receiverId: receiverId,
          senderId: currentUserId,
          senderName:
              _resolvedCurrentUserName.isNotEmpty
                  ? _resolvedCurrentUserName
                  : currentUserName,
          senderImageUrl:
              _resolvedSenderImageUrl.isNotEmpty
                  ? _resolvedSenderImageUrl
                  : (senderImageUrl ?? ''),
          messageBody: caption ?? messageText,
          messageType: messageType,
          chatReferenceId: currentUserId,
        );
      }
      _cancelTokens.remove(tempId);

      Future.delayed(const Duration(seconds: 2), () {
        if (!isClosed) {
          cachedMessages.removeWhere((m) => m.id == tempId);
          emit(MessagesSuccessLoaded(messages: List.from(cachedMessages)));
        }
      });
    } on UploadCanceledException {
      return;
    } catch (e) {
      _cancelTokens.remove(tempId);

      if (e is dio_pkg.DioException &&
          e.type == dio_pkg.DioExceptionType.cancel) {
        debugPrint("User canceled the upload");
        return;
      }
      if (e.toString().contains('session_expired')) {
        emit(MessagesError('Your session has expired; please log in again'));
        return;
      } else {
        debugPrint('Error uploading file: $e');

        _cancelTokens.remove(tempId);
        uploadProgressMap.remove(tempId);

        cachedMessages.removeWhere((m) => m.id == tempId);

        emit(MessagesSuccessLoaded(messages: List.from(cachedMessages)));
      }

      unawaited(ConnectivityBannerController.notifyIfOffline());

      debugPrint('error sending message: $e');
      emit(
        MessagesError("Failed to send message. Please check your connection."),
      );

      emit(MessagesSuccessLoaded(messages: currentMessages));

      uploadProgressMap.remove(tempId);
    }
  }

  Future<void> editMessage({
    required String messageId,
    required String newText,
  }) async {
    final trimmed = newText.trim();
    if (trimmed.isEmpty) return;

    final target = cachedMessages.firstWhere(
      (m) => m.id == messageId,
      orElse: () => cachedMessages.first,
    );
    final isCaptionEdit =
        target.messageType == 'image' || target.messageType == 'video';

    cachedMessages =
        cachedMessages.map((m) {
          if (m.id != messageId) return m;
          return isCaptionEdit
              ? m.copyWith(caption: trimmed, isEdited: true)
              : m.copyWith(text: trimmed, isEdited: true);
        }).toList();
    // _emitLoaded();
    emit(MessagesSuccessLoaded(messages: cachedMessages));

    try {
      await _chatServices.editMessage(
        messageId: messageId,
        newText: trimmed,
        isCaptionEdit: isCaptionEdit,
      );
    } catch (e) {
      debugPrint('Error editing message: $e');
    }
  }

  // ignore: unused_field
  String _resolvedCurrentUserName = '';
  // ignore: unused_field
  String _resolvedSenderImageUrl = '';

  Future<void> loadCurrentUserInfo() async {
    try {
      final info = await _chatServices.getCurrentUserInfo(currentUserId);
      _resolvedCurrentUserName = info['name'] ?? currentUserName;
      _resolvedSenderImageUrl = info['imageUrl'] ?? senderImageUrl ?? '';
    } catch (_) {}
  }

  final Map<String, dio_pkg.CancelToken> _cancelTokens = {};
  @override
  void cancelUpload(String tempId) {
    if (_cancelTokens.containsKey(tempId)) {
      _cancelTokens[tempId]!.cancel();
      _cancelTokens.remove(tempId);
      uploadProgressMap.remove(tempId);
      _disposeProgressNotifier(tempId);
      if (state is MessagesSending) {
        final currentList = (state as MessagesSending).messages;
        final updatedList = currentList!.where((m) => m.id != tempId).toList();
        emit(MessagesSuccessLoaded(messages: updatedList));
      }
    }
  }

  void setReplyMessage(MessageModel message) {
    replyToMessage.value = message;
  }

  void cancelReply() {
    replyToMessage.value = null;
  }

  int? findMessageIndex(String messageId) {
    final index = cachedMessages.indexWhere((m) => m.id == messageId);
    return index == -1 ? null : index;
  }

  final ValueNotifier<String?> highlightedMessageId = ValueNotifier(null);

  Future<void> scrollToMessage({
    required String messageId,
    required ItemScrollController itemScrollController,
  }) async {
    final index = cachedMessages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;

    await itemScrollController.scrollTo(
      index: index,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
      alignment: 0.3,
    );

    highlightedMessageId.value = messageId;
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!isClosed) highlightedMessageId.value = null;
    });
  }

  Future<void> deleteMessage({
    required String messageId,
    required String receiverId,
  }) async {
    try {
      await _chatServices.deleteMessage(messageId: messageId);
    } catch (e) {
      debugPrint('error deleting message: $e');
      emit(MessagesError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    chatPermission.dispose();
    blockStatus.dispose();
    _blockStatusSubscription?.cancel();
    highlightedMessageId.dispose();
    searchController.dispose();
    for (final notifier in uploadProgressNotifiers.values) {
      notifier.dispose();
    }
    _messageSubscription?.cancel();
    isAtBottomNotifier.dispose();
    pendingNewCountNotifier.dispose();
    return super.close();
  }
}
