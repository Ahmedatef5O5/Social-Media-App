import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../notifications/repository/notifications_repository.dart';
import '../../models/group_model.dart';
import '../../models/groupe_message_model.dart';
import '../../services/group_chat_services.dart';
import '../group_list_cubit/group_list_cubit.dart';
import 'group_details_state.dart';

class GroupDetailsCubit extends Cubit<GroupDetailsState> {
  final GroupChatServices _services;
  final GroupModel group;
  final GroupListCubit groupListCubit;

  StreamSubscription? _messagesSubscription;
  StreamSubscription? _readReceiptsSubscription;
  StreamSubscription? _typingSubscription;
  StreamSubscription? _reactionsSubscription;
  Timer? _typingDebounce;

  List<GroupMessageModel> cachedMessages = [];
  List<String> _typingUserIds = [];
  Map<String, Map<String, String>> _reactionsCache = {};
  final Map<String, double> uploadProgressMap = {};
  bool _isFirstLoad = true;

  final ValueNotifier<GroupMessageModel?> replyToMessage = ValueNotifier(null);
  final ValueNotifier<String?> highlightedMessageId = ValueNotifier(null);

  String get currentUserId => Supabase.instance.client.auth.currentUser!.id;

  GroupDetailsCubit(this._services, this.group, this.groupListCubit)
    : super(GroupDetailsLoading());

  void init() {
    emit(GroupDetailsLoading());
    groupListCubit.setActiveGroupId(group.id);
    _listenMessages();
    _listenReadReceipts();
    _listenTyping();
    _listenReactions();
    markRead();
  }

  void _listenMessages() {
    _messagesSubscription?.cancel();
    _messagesSubscription = _services.getGroupMessagesStream(group.id).listen((
      messages,
    ) {
      final enriched =
          messages.map((msg) {
            final reactions = _reactionsCache[msg.id] ?? {};
            return msg.copyWith(reactions: reactions);
          }).toList();

      cachedMessages = enriched;
      _isFirstLoad = false;
      _emitLoaded();

      // Mark read in DB
      markRead();

      if (enriched.isNotEmpty) {
        final latest = enriched.first;

        groupListCubit.updateGroupLastMessage(
          groupId: group.id,
          message: latest.text,
          messageId: latest.id,
          messageType: latest.messageType,
          createdAt: latest.createdAt,
          lastMessageSenderId: latest.senderId,
          lastMessageSenderName: latest.senderName,
        );
      }
    });
  }

  void _listenReadReceipts() {
    _readReceiptsSubscription?.cancel();
    _readReceiptsSubscription = _services
        .getReadReceiptsStream(group.id)
        .listen((receipts) {
          if (receipts.isEmpty) return;

          final receiptMap = <String, Set<String>>{};
          for (final r in receipts) {
            final id = r['id'] as String?;
            final readByRaw = r['read_by'];
            if (id == null) continue;
            Set<String> readBySet = {};
            if (readByRaw is List) {
              readBySet = readByRaw.map((e) => e.toString()).toSet();
            }
            receiptMap[id] = readBySet;
          }

          bool changed = false;
          cachedMessages =
              cachedMessages.map((msg) {
                final newReadBy = receiptMap[msg.id];
                if (newReadBy != null && newReadBy != msg.readBy) {
                  changed = true;
                  return msg.copyWith(readBy: newReadBy);
                }
                return msg;
              }).toList();

          if (changed) _emitLoaded();
        });
  }

  void _listenReactions() {
    _reactionsSubscription?.cancel();
    _reactionsSubscription = _services.getReactionsStream(group.id).listen((
      reactionsList,
    ) {
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

      cachedMessages =
          cachedMessages.map((msg) {
            final reactions = _reactionsCache[msg.id] ?? {};
            return msg.copyWith(reactions: reactions);
          }).toList();
      _emitLoaded();
    });
  }

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
    if (_isFirstLoad) return;
    emit(
      GroupDetailsLoaded(
        messages: cachedMessages,
        typingUserIds: _typingUserIds,
        uploadProgress: uploadProgressMap,
      ),
    );
  }

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

    final userProfile =
        await Supabase.instance.client
            .from('users')
            .select('name, image_url')
            .eq('id', currentUserId)
            .maybeSingle();

    final senderName = (userProfile?['name'] as String?) ?? 'Me';
    final senderAvatar = (userProfile?['image_url'] as String?) ?? '';

    final reply = replyToMessage.value;
    replyToMessage.value = null;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    final tempMsg = GroupMessageModel(
      id: tempId,
      groupId: group.id,
      senderId: currentUserId,
      senderName: senderName,
      senderAvatar: senderAvatar,
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
      final memberIds =
          group.members
              .map((m) => m.userId)
              .where((id) => id != currentUserId)
              .toList();

      for (final memberId in memberIds) {
        await NotificationRepository.instance.notifyGroupMessage(
          receiverId: memberId,
          senderId: currentUserId,
          senderName: senderName,
          senderImageUrl: senderAvatar,
          groupId: group.id,
          groupName: group.name,
          messageBody: text.isNotEmpty ? text : (caption ?? ''),
          messageType: messageType,
        );
      }

      final rawPreview = switch (messageType) {
        'image' => caption ?? '',
        'video' => caption ?? '',
        'voice' => '',
        _ => text,
      };

      groupListCubit.updateGroupLastMessage(
        groupId: group.id,
        message: rawPreview,
        messageId: tempId,
        messageType: messageType,
        createdAt: DateTime.now(),
        lastMessageSenderId: currentUserId,
        lastMessageSenderName: senderName,
      );

      cachedMessages.removeWhere((m) => m.id == tempId);
    } catch (e) {
      cachedMessages.removeWhere((m) => m.id == tempId);
      uploadProgressMap.remove(tempId);
      emit(GroupDetailsError(e.toString()));
    }
  }

  Future<void> deleteMessage(String messageId) async {
    cachedMessages.removeWhere((m) => m.id == messageId);
    _emitLoaded();
    await _services.deleteGroupMessage(messageId);
  }

  Future<void> toggleReaction({
    required String messageId,
    required String emoji,
  }) async {
    final currentEmoji = _reactionsCache[messageId]?[currentUserId];

    _reactionsCache[messageId] ??= {};

    if (currentEmoji == emoji) {
      _reactionsCache[messageId]!.remove(currentUserId);
    } else {
      _reactionsCache[messageId]![currentUserId] = emoji;
    }

    try {
      await _services.toggleReaction(
        messageId: messageId,
        emoji: emoji,
        currentEmoji: currentEmoji,
      );
    } catch (e) {
      if (currentEmoji == null) {
        _reactionsCache[messageId]!.remove(currentUserId);
      } else {
        _reactionsCache[messageId]![currentUserId] = currentEmoji;
      }
      rethrow;
    }
  }

  void onTyping() {
    _services.setTyping(group.id, true);
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(seconds: 3), () {
      _services.setTyping(group.id, false);
    });
  }

  Future<void> markRead() async {
    groupListCubit.resetGroupUnreadCount(group.id);
    await _services.markGroupMessagesRead(group.id);
  }

  int? findMessageIndex(String messageId) {
    final index = cachedMessages.indexWhere((m) => m.id == messageId);
    return index == -1 ? null : index;
  }

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

  GroupModel get currentGroup => group;

  void onGroupAvatarUpdated(String newUrl) {}

  @override
  Future<void> close() {
    // Mark read and reset count before clearing active group
    groupListCubit.resetGroupUnreadCount(group.id);
    _services.markGroupMessagesRead(group.id);

    // ✅ FIX: Update watermark one final time on exit so GroupListCubit
    // knows everything visible was read before we left.
    // groupListCubit.markGroupReadUntilNow(group.id);

    groupListCubit.setActiveGroupId(null);

    _messagesSubscription?.cancel();
    _readReceiptsSubscription?.cancel();
    _typingSubscription?.cancel();
    _reactionsSubscription?.cancel();
    _typingDebounce?.cancel();
    replyToMessage.dispose();
    highlightedMessageId.dispose();
    return super.close();
  }
}
