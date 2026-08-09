import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:social_media_app/core/chat_shared/controllers/chat_search_controller.dart';
import 'package:social_media_app/core/connectivity/services/connectivity_banner_controller.dart';
import 'package:social_media_app/core/mentions/mentions.dart';
import '../../../../core/cache/repository/media_cache_repository.dart';
import '../../../../core/cache/services/messages_snapshot_cache.dart';
import '../../../../core/presence/model/chat_action_type.dart';
import '../../../../core/services/fcm_services.dart';
import '../../../../core/services/supabase_storage_services.dart';
import '../../../../core/supabase/supabase_provider.dart';
import '../../../../core/utilities/supabase_constants.dart';
import '../../../../core/audio/voice_recorder/services/audio_compression_service.dart';
import '../../../../core/helpers/selected_message_star_controller.dart';
import '../../../notifications/repository/notifications_repository.dart';
import '../../../reactions/services/reaction_profile_resolver.dart';
import '../../helpers/group_chat_clear_store.dart';
import '../../models/group_header_stats.dart';
import '../../models/group_model.dart';
import '../../models/group_presence_entry.dart';
import '../../models/groupe_message_model.dart';
import '../../services/group_chat_services.dart';
import '../group_list_cubit/group_list_cubit.dart';
part 'group_details_state.dart';
part 'group_messages_stream_mixin.dart';
part 'group_mentions_mixin.dart';
part 'group_reactions_mixin.dart';
part 'group_media_upload_mixin.dart';
part 'group_edit_mixin.dart';
part 'group_selection_mixin.dart';

class GroupDetailsCubit extends Cubit<GroupDetailsState>
    with
        GroupMessagesStreamMixin,
        GroupMentionsMixin,
        GroupReactionsMixin,
        GroupEditMixin,
        GroupMediaUploadMixin,
        GroupSelectionMixin {
  @override
  final GroupChatServices _services;
  @override
  final GroupModel group;
  @override
  final GroupListCubit groupListCubit;
  @override
  final MediaCacheRepository _mediaCacheRepository;

  @override
  final AudioCompressionService _audioCompressionService;

  static final _snapshotCache = MessagesSnapshotCache<GroupMessageModel>(
    toCacheJson: (m) => m.toCacheJson(),
    fromJson: GroupMessageModel.fromJson,
  );

  GroupDetailsCubit(
    this._services,
    this.group,
    this.groupListCubit,
    this._mediaCacheRepository, {
    AudioCompressionService? audioCompressionService,
  }) : _audioCompressionService =
           audioCompressionService ?? AudioCompressionService(),
       super(GroupDetailsLoading());

  @override
  List<GroupMessageModel> cachedMessages = [];
  @override
  String? _messagesSnapshotKey;

  GroupPresenceSnapshot get presence => _presence;
  Stream<GroupHeaderStats> watchHeaderStats() =>
      _services.watchGroupHeaderStats(group.id);

  @override
  final Map<String, double> uploadProgressMap = {};
  final Map<String, ValueNotifier<double>> uploadProgressNotifiers = {};

  @override
  final ValueNotifier<GroupMessageModel?> replyToMessage = ValueNotifier(null);
  final ValueNotifier<GroupMessageModel?> editingMessage = ValueNotifier(null);
  final ValueNotifier<String?> highlightedMessageId = ValueNotifier(null);

  @override
  String get currentUserId => SupabaseProvider.id;
  @override
  bool isMember = true;
  bool get hasConfirmedInitialLoad => _hasReceivedFirstStreamEvent;

  final GroupChatReactionProfileResolver reactionProfileResolver =
      GroupChatReactionProfileResolver();

  late final ChatSearchController<GroupMessageModel> searchController =
      ChatSearchController<GroupMessageModel>(
        getMessages: () => cachedMessages,
        getSearchableText:
            (m) => (m.caption?.isNotEmpty == true ? m.caption! : m.text),
        getId: (m) => m.id,
      );

  void init() {
    _messagesSnapshotKey = 'group_messages_snapshot_${group.id}';

    final listState = groupListCubit.state;
    isMember =
        listState is GroupListLoaded
            ? listState.groups
                .firstWhere((g) => g.id == group.id, orElse: () => group)
                .isMember
            : group.isMember;

    final diskMessages = _readMessagesSnapshot(_messagesSnapshotKey!);
    if (diskMessages.isNotEmpty) {
      for (var m in diskMessages) {
        if (m.mentions.isNotEmpty) {
          _mentionsCache[m.id] = List<MentionRef>.from(m.mentions);
        }

        if (m.reactions.isNotEmpty) {
          _reactionsCache[m.id] = Map<String, String>.from(m.reactions);
        }
      }

      cachedMessages = diskMessages;
      _isFirstLoad = false;
      emit(
        GroupDetailsLoaded(
          messages: cachedMessages,
          presence: _presence,
          uploadProgress: uploadProgressMap,
          isMember: isMember,
        ),
      );
    } else {
      emit(GroupDetailsLoading());
    }

    groupListCubit.setActiveGroupId(group.id);
    _listenMembership();
    _listenMentions();
    _listenReactions();
    _listenMessages();
    _listenReadReceipts();
    _listenPresence();
    markRead();
  }

  @override
  void _emitLoaded({bool force = false}) {
    if (_isFirstLoad && !force) return;
    emit(
      GroupDetailsLoaded(
        messages: cachedMessages,
        presence: _presence,
        uploadProgress: uploadProgressMap,
        isMember: isMember,
      ),
    );
  }

  Future<List<String>> getMemberIdsForMentions() =>
      _services.getGroupMemberIds(group.id);

  @override
  void _persistMessagesSnapshot(String key, List<GroupMessageModel> messages) {
    return _snapshotCache.persist(key, messages);
  }

  List<GroupMessageModel> _readMessagesSnapshot(String key) {
    return _snapshotCache.read(key);
  }

  @override
  Future<void> markRead() async {
    if (!isMember) return;
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

  ValueNotifier<double> progressNotifierFor(String messageId) {
    return uploadProgressNotifiers.putIfAbsent(
      messageId,
      () => ValueNotifier<double>(0),
    );
  }

  void disposeProgressNotifier(String messageId) {
    uploadProgressNotifiers.remove(messageId)?.dispose();
  }

  @override
  Future<void> close() {
    groupListCubit.resetGroupUnreadCount(group.id);
    if (isMember) {
      _services.markGroupMessagesRead(group.id);
    }
    groupListCubit.setActiveGroupId(null);

    _messagesSubscription?.cancel();
    _readReceiptsSubscription?.cancel();
    _typingSubscription?.cancel();
    _membershipSubscription?.cancel();
    _typingDebounce?.cancel();

    replyToMessage.dispose();
    editingMessage.dispose();
    highlightedMessageId.dispose();
    return super.close();
  }
}
