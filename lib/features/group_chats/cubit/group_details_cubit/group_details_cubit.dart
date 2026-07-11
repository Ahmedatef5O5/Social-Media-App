import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:social_media_app/core/cache/services/local_snapshot_store.dart';
import 'package:social_media_app/core/connectivity/services/connectivity_banner_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_storage_services.dart';
import '../../../../core/utilities/supabase_constants.dart';
import '../../../notifications/repository/notifications_repository.dart';
import '../../models/group_model.dart';
import '../../models/groupe_message_model.dart';
import '../../services/group_chat_services.dart';
import '../group_list_cubit/group_list_cubit.dart';
part 'group_details_state.dart';
part 'group_messages_stream_mixin.dart';
part 'group_reactions_mixin.dart';
part 'group_media_upload_mixin.dart';

const int kMaxCachedGroupMessagesSnapshot = 60;

class GroupDetailsCubit extends Cubit<GroupDetailsState>
    with GroupMessagesStreamMixin, GroupReactionsMixin, GroupMediaUploadMixin {
  @override
  final GroupChatServices _services;
  @override
  final GroupModel group;
  @override
  final GroupListCubit groupListCubit;

  GroupDetailsCubit(this._services, this.group, this.groupListCubit)
    : super(GroupDetailsLoading());

  @override
  List<GroupMessageModel> cachedMessages = [];
  @override
  String? _messagesSnapshotKey;

  @override
  final Map<String, double> uploadProgressMap = {};

  @override
  final ValueNotifier<GroupMessageModel?> replyToMessage = ValueNotifier(null);
  final ValueNotifier<String?> highlightedMessageId = ValueNotifier(null);

  @override
  String get currentUserId => Supabase.instance.client.auth.currentUser!.id;

  void init() {
    _messagesSnapshotKey = 'group_messages_snapshot_${group.id}';
    final diskMessages = _readMessagesSnapshot(_messagesSnapshotKey!);
    if (diskMessages.isNotEmpty) {
      for (var m in diskMessages) {
        if (m.reactions.isNotEmpty) {
          _reactionsCache[m.id] = Map<String, String>.from(m.reactions);
        }
      }

      cachedMessages = diskMessages;
      _isFirstLoad = false;
      emit(
        GroupDetailsLoaded(
          messages: cachedMessages,
          typingUserIds: _typingUserIds,
          uploadProgress: uploadProgressMap,
        ),
      );
    } else {
      emit(GroupDetailsLoading());
    }

    groupListCubit.setActiveGroupId(group.id);
    _listenMessages();
    _listenReadReceipts();
    _listenTyping();
    _listenReactions();
    markRead();
  }

  @override
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

  @override
  void _persistMessagesSnapshot(String key, List<GroupMessageModel> messages) {
    unawaited(
      LocalSnapshotStore.instance.saveList(
        key,
        messages
            .take(kMaxCachedGroupMessagesSnapshot)
            .map((m) => m.toCacheJson())
            .toList(),
      ),
    );
  }

  List<GroupMessageModel> _readMessagesSnapshot(String key) {
    try {
      return LocalSnapshotStore.instance
          .readList(key)
          .map(GroupMessageModel.fromJson)
          .toList();
    } catch (e) {
      debugPrint('Failed to read group messages snapshot from disk: $e');
      return [];
    }
  }

  @override
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
    groupListCubit.resetGroupUnreadCount(group.id);
    _services.markGroupMessagesRead(group.id);

    groupListCubit.setActiveGroupId(null);

    replyToMessage.dispose();
    highlightedMessageId.dispose();
    return super.close();
  }
}
