import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/group_model.dart';
import '../../models/groupe_message_model.dart';
import '../../services/group_chat_services.dart';
import 'group_details_state.dart';

// ──────────────── Cubit ────────────────
class GroupDetailsCubit extends Cubit<GroupDetailsState> {
  final GroupChatServices _services;
  final GroupModel group;

  StreamSubscription? _messagesSubscription;
  StreamSubscription? _typingSubscription;
  StreamSubscription? _reactionsSubscription;
  Timer? _typingDebounce;

  List<GroupMessageModel> cachedMessages = [];
  List<String> _typingUserIds = [];
  Map<String, Map<String, String>> _reactionsCache =
      {}; // messageId -> {userId: emoji}
  final Map<String, double> uploadProgressMap = {};

  final ValueNotifier<GroupMessageModel?> replyToMessage = ValueNotifier(null);
  final ValueNotifier<String?> highlightedMessageId = ValueNotifier(null);

  String get currentUserId => Supabase.instance.client.auth.currentUser!.id;

  GroupDetailsCubit(this._services, this.group) : super(GroupDetailsInitial());

  void init() {
    _listenMessages();
    _listenTyping();
    _listenReactions();
    markRead();
  }

  // ── Messages ──
  void _listenMessages() {
    _messagesSubscription?.cancel();
    _messagesSubscription = _services.getGroupMessagesStream(group.id).listen((
      messages,
    ) {
      // Merge reactions into messages
      final enriched =
          messages.map((msg) {
            final reactions = _reactionsCache[msg.id] ?? {};
            return msg.copyWith(reactions: reactions);
          }).toList();

      cachedMessages = enriched;
      _emitLoaded();
    });
  }

  // ── Reactions stream ──
  void _listenReactions() {
    _reactionsSubscription?.cancel();
    _reactionsSubscription = _services.getReactionsStream(group.id).listen((
      reactionsList,
    ) {
      // Rebuild reactions cache
      _reactionsCache = {};
      for (final r in reactionsList) {
        final msgId = r['message_id'] as String?;
        final userId = r['user_id'] as String?;
        final emoji = r['reaction'] as String?;
        if (msgId != null && userId != null && emoji != null) {
          _reactionsCache[msgId] ??= {};
          _reactionsCache[msgId]![userId] = emoji;
        }
      }

      // Re-enrich messages
      cachedMessages =
          cachedMessages.map((msg) {
            final reactions = _reactionsCache[msg.id] ?? {};
            return msg.copyWith(reactions: reactions);
          }).toList();
      _emitLoaded();
    });
  }

  // ── Typing ──
  void _listenTyping() {
    _typingSubscription?.cancel();
    _typingSubscription = _services.getTypingUsersStream(group.id).listen((
      typingIds,
    ) {
      _typingUserIds = typingIds;
      _emitLoaded();
    });
  }

  void _emitLoaded() {
    emit(
      GroupDetailsLoaded(
        messages: cachedMessages,
        typingUserIds: _typingUserIds,
        uploadProgress: uploadProgressMap,
      ),
    );
  }

  // ── Send Message ──
  Future<void> sendMessage({
    required String text,
    String messageType = 'text',
    File? imageFile,
    File? videoFile,
    File? voiceFile,
    String? caption,
  }) async {
    if (text.trim().isEmpty &&
        imageFile == null &&
        videoFile == null &&
        voiceFile == null) {
      return;
    }

    final reply = replyToMessage.value;
    replyToMessage.value = null;

    // Optimistic temp message
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMsg = GroupMessageModel(
      id: tempId,
      groupId: group.id,
      senderId: currentUserId,
      senderName: 'Me',
      text: text,
      createdAt: DateTime.now(),
      messageType: messageType,
      replyToMessageId: reply?.id,
      replyToText: reply?.text,
      replyToSenderId: reply?.senderId,
      replyToSenderName: reply?.senderName,
      replyToMessageType: reply?.messageType,
    );
    cachedMessages = [tempMsg, ...cachedMessages];
    _emitLoaded();

    try {
      String? uploadedImageUrl;
      String? uploadedVideoUrl;
      String? uploadedVoiceUrl;

      if (imageFile != null) {
        uploadProgressMap[tempId] = 0;
        uploadedImageUrl = await _services.uploadGroupFile(
          imageFile,
          'image',
          onProgress: (p) {
            uploadProgressMap[tempId] = p;
            _emitLoaded();
          },
        );
        uploadProgressMap.remove(tempId);
      }

      if (videoFile != null) {
        uploadProgressMap[tempId] = 0;
        uploadedVideoUrl = await _services.uploadGroupFile(
          videoFile,
          'video',
          onProgress: (p) {
            uploadProgressMap[tempId] = p;
            _emitLoaded();
          },
        );
        uploadProgressMap.remove(tempId);
      }

      if (voiceFile != null) {
        uploadedVoiceUrl = await _services.uploadGroupFile(voiceFile, 'voice');
      }

      await _services.sendGroupMessage(
        groupName: group.name,
        groupId: group.id,
        text: text,
        messageType: messageType,
        imageUrl: uploadedImageUrl,
        videoUrl: uploadedVideoUrl,
        voiceUrl: uploadedVoiceUrl,
        caption: caption,
        replyTo: reply, 
        
      );

      // Remove temp message (stream will reload)
      cachedMessages.removeWhere((m) => m.id == tempId);
    } catch (e) {
      cachedMessages.removeWhere((m) => m.id == tempId);
      uploadProgressMap.remove(tempId);
      emit(GroupDetailsError(e.toString()));
    }
  }

  // ── Delete ──
  Future<void> deleteMessage(String messageId) async {
    cachedMessages.removeWhere((m) => m.id == messageId);
    _emitLoaded();
    await _services.deleteGroupMessage(messageId);
  }

  // ── Reaction ──
  Future<void> toggleReaction({
    required String messageId,
    required String emoji,
  }) async {
    final currentEmoji = _reactionsCache[messageId]?[currentUserId];
    await _services.toggleReaction(
      messageId: messageId,
      emoji: emoji,
      currentEmoji: currentEmoji,
    );
  }

  // ── Typing ──
  void onTyping() {
    _services.setTyping(group.id, true);
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(seconds: 3), () {
      _services.setTyping(group.id, false);
    });
  }

  // ── Read ──
  Future<void> markRead() async {
    await _services.markGroupMessagesRead(group.id);
  }

  // ── Highlight message (for reply navigation) ──
  void highlightMessage(String messageId) {
    highlightedMessageId.value = messageId;
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!isClosed) highlightedMessageId.value = null;
    });
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    _typingSubscription?.cancel();
    _reactionsSubscription?.cancel();
    _typingDebounce?.cancel();
    replyToMessage.dispose();
    highlightedMessageId.dispose();
    return super.close();
  }
}
