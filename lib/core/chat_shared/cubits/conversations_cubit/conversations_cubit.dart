import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/supabase_error_mapper.dart';
import '../../../../core/toast/app_toast.dart';
import '../../../../features/group_chats/cubit/group_list_cubit/group_list_cubit.dart';
import '../../../../features/group_chats/models/group_model.dart';
import '../../../../features/group_chats/services/group_chat_services.dart';
import '../../../../features/single_chats/cubit/chats_cubit/chats_cubit.dart';
import '../../../../features/single_chats/models/chat_user_model.dart';
import '../../../supabase/supabase_provider.dart';
import '../../helpers/chat_mute_status_cache.dart';
import '../../models/conversation_flags.dart';
import '../../models/conversation_item.dart';
import '../../models/conversation_ref.dart';
import '../../services/chat_mute_service.dart';
import '../../services/conversation_flags_store.dart';
part 'conversations_state.dart';

class ConversationsCubit extends Cubit<ConversationsState> {
  final ChatsCubit chatsCubit;
  final GroupListCubit groupListCubit;
  final GroupChatServices groupChatServices;
  final ChatMuteService _chatMuteService = ChatMuteService();

  StreamSubscription? _chatsSub;
  StreamSubscription? _groupsSub;
  RealtimeChannel? _chatMutesChannel;

  List<ChatUserModel> _rawChats = [];
  List<GroupModel> _rawGroups = [];

  final Map<String, bool> _liveSingleChatMutes = {};

  ConversationsCubit({
    required this.chatsCubit,
    required this.groupListCubit,
    required this.groupChatServices,
  }) : super(const ConversationsInitial()) {
    _rawChats = _extractChats(chatsCubit.state);
    _rawGroups = _extractGroups(groupListCubit.state);

    _chatsSub = chatsCubit.stream.listen((s) {
      _rawChats = _extractChats(s);
      _recompute();
    });
    _groupsSub = groupListCubit.stream.listen((s) {
      _rawGroups = _extractGroups(s);
      _recompute();
    });

    _subscribeSingleChatMutes();
    _recompute();
  }

  void _subscribeSingleChatMutes() {
    final currentUserId = SupabaseProvider.id;
    final supabase = SupabaseProvider.client;

    final channelName = 'conversations_chat_mutes_$currentUserId';
    supabase.removeChannel(supabase.channel(channelName));
    _chatMutesChannel =
        supabase.channel(channelName)
          ..onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'chat_mutes',
            callback: (payload) {
              final row =
                  payload.eventType == PostgresChangeEvent.delete
                      ? payload.oldRecord
                      : payload.newRecord;
              final ownerId = row['owner_id'] as String?;
              if (ownerId != currentUserId) return;

              final peerId = row['peer_id'] as String?;
              if (peerId == null) return;

              if (payload.eventType == PostgresChangeEvent.delete) {
                _liveSingleChatMutes.remove(peerId);
                unawaited(ChatMuteStatusCache.instance.write(peerId, false));
              } else {
                final muted = row['is_muted'] as bool? ?? false;
                _liveSingleChatMutes[peerId] = muted;
                unawaited(ChatMuteStatusCache.instance.write(peerId, muted));
              }
              _recompute();
            },
          )
          ..subscribe();

    _loadInitialSingleChatMutes();
  }

  Future<void> _loadInitialSingleChatMutes() async {
    try {
      final rows = await SupabaseProvider.client
          .from('chat_mutes')
          .select('peer_id, is_muted')
          .eq('owner_id', SupabaseProvider.id);
      for (final row in (rows as List)) {
        final peerId = row['peer_id'] as String?;
        if (peerId == null) continue;
        final muted = row['is_muted'] as bool? ?? false;
        _liveSingleChatMutes[peerId] = muted;
        unawaited(ChatMuteStatusCache.instance.write(peerId, muted));
      }
      _recompute();
    } catch (e) {
      debugPrint('[ConversationsCubit] initial chat_mutes load failed: $e');
    }
  }

  List<ChatUserModel> _extractChats(ChatsState s) =>
      s is ChatsSuccessloaded ? s.chats : _rawChats;

  List<GroupModel> _extractGroups(GroupListState s) =>
      s is GroupListLoaded ? s.groups : _rawGroups;

  void _recompute() {
    final store = ConversationFlagsStore.instance;

    final chatItems = _rawChats.map((c) {
      final ref = ConversationRef(type: ConversationType.single, id: c.id);
      var flags = store.flagsFor(ref);

      final liveMuted = _liveSingleChatMutes[c.id];
      if (liveMuted != null) {
        flags = flags.copyWith(muteOverride: liveMuted);
      } else {
        final cached = ChatMuteStatusCache.instance.read(c.id);
        if (cached != null) {
          flags = flags.copyWith(muteOverride: cached);
        }
      }

      return ConversationItem.fromChat(c, flags);
    });

    final groupItems = _rawGroups.where((g) => g.isMember).map((g) {
      final ref = ConversationRef(type: ConversationType.group, id: g.id);
      return ConversationItem.fromGroup(g, store.flagsFor(ref));
    });

    final merged = [...chatItems, ...groupItems];

    final visible =
        merged.where((i) => !i.isArchived).toList()..sort(_comparator);
    final archived =
        merged.where((i) => i.isArchived).toList()..sort(_archiveComparator);

    emit(ConversationsLoaded(items: visible, archivedItems: archived));
  }

  int _comparator(ConversationItem a, ConversationItem b) {
    if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
    if (a.isPinned && b.isPinned) {
      final aPin = a.flags.pinnedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bPin = b.flags.pinnedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final pinCmp = bPin.compareTo(aPin);
      if (pinCmp != 0) return pinCmp;
    }
    final aTime = a.lastActivityAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bTime = b.lastActivityAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bTime.compareTo(aTime);
  }

  int _archiveComparator(ConversationItem a, ConversationItem b) {
    if (a.flags.isPinnedInArchive != b.flags.isPinnedInArchive) {
      return a.flags.isPinnedInArchive ? -1 : 1;
    }
    if (a.flags.isPinnedInArchive && b.flags.isPinnedInArchive) {
      final aPin =
          a.flags.archivePinnedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bPin =
          b.flags.archivePinnedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final pinCmp = bPin.compareTo(aPin);
      if (pinCmp != 0) return pinCmp;
    }
    final aTime = a.lastActivityAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bTime = b.lastActivityAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bTime.compareTo(aTime);
  }

  List<ConversationItem> filtered(ConversationTab tab) {
    final items =
        state is ConversationsLoaded
            ? (state as ConversationsLoaded).items
            : const <ConversationItem>[];

    switch (tab) {
      case ConversationTab.all:
        return items;
      case ConversationTab.chats:
        return items.where((i) => i.kind == ConversationKind.single).toList();
      case ConversationTab.groups:
        return items.where((i) => i.kind == ConversationKind.group).toList();
      case ConversationTab.favorites:
        return items.where((i) => i.isFavorite).toList();
      case ConversationTab.unread:
        return items.where((i) => i.unreadCount > 0).toList();
    }
  }

  SelectionFlagState _flagState(
    Set<ConversationRef> refs,
    bool Function(ConversationFlags) test,
  ) {
    final values =
        refs
            .map((r) => test(ConversationFlagsStore.instance.flagsFor(r)))
            .toSet();
    if (values.length > 1) return SelectionFlagState.mixed;
    return (values.isNotEmpty && values.first)
        ? SelectionFlagState.allOn
        : SelectionFlagState.allOff;
  }

  SelectionFlagState pinnedState(Set<ConversationRef> refs) =>
      _flagState(refs, (f) => f.isPinned);
  SelectionFlagState favoriteState(Set<ConversationRef> refs) =>
      _flagState(refs, (f) => f.isFavorite);
  SelectionFlagState archivedState(Set<ConversationRef> refs) =>
      _flagState(refs, (f) => f.isArchived);
  SelectionFlagState archivePinnedState(Set<ConversationRef> refs) =>
      _flagState(refs, (f) => f.isPinnedInArchive);

  SelectionFlagState mutedState(Set<ConversationRef> refs) {
    final items =
        state is ConversationsLoaded
            ? [
              ...(state as ConversationsLoaded).items,
              ...(state as ConversationsLoaded).archivedItems,
            ]
            : const <ConversationItem>[];

    final values =
        refs
            .map(
              (r) =>
                  items.firstWhereOrNull((i) => i.ref == r)?.isMuted ?? false,
            )
            .toSet();

    if (values.length > 1) return SelectionFlagState.mixed;
    return (values.isNotEmpty && values.first)
        ? SelectionFlagState.allOn
        : SelectionFlagState.allOff;
  }

  Future<void> _applyPinned(ConversationRef ref, bool value) =>
      ConversationFlagsStore.instance.setPinned(ref, value);

  Future<void> _applyFavorite(ConversationRef ref, bool value) =>
      ConversationFlagsStore.instance.setFavorite(ref, value);

  Future<void> _applyArchived(ConversationRef ref, bool value) async {
    await ConversationFlagsStore.instance.setArchived(ref, value);
    if (!value) {
      await ConversationFlagsStore.instance.setArchivePinned(ref, false);
    }
    if (ref.type == ConversationType.group) {
      await _syncGroupMuteWithArchive(ref, archiving: value);
    } else {
      await _syncSingleChatMuteWithArchive(ref, archiving: value);
    }
  }

  Future<void> _applyArchivePinned(ConversationRef ref, bool value) =>
      ConversationFlagsStore.instance.setArchivePinned(ref, value);

  Future<void> setPinned(ConversationRef ref, bool value) async {
    await _applyPinned(ref, value);
    _recompute();
  }

  Future<void> setFavorite(ConversationRef ref, bool value) async {
    await _applyFavorite(ref, value);
    _recompute();
  }

  Future<void> setArchived(ConversationRef ref, bool value) async {
    await _applyArchived(ref, value);
    _recompute();
  }

  Future<void> setArchivePinned(ConversationRef ref, bool value) async {
    await _applyArchivePinned(ref, value);
    _recompute();
  }

  Future<void> bulkSetArchivePinned(
    Set<ConversationRef> refs,
    bool value,
  ) async {
    for (final ref in refs) {
      await _applyArchivePinned(ref, value);
    }
    _recompute();
  }

  Future<void> _applyMuted(ConversationRef ref, bool value) async {
    if (ref.type == ConversationType.group) {
      await _setGroupMuteOnBackend(ref.id, value);
      return;
    }

    final previousOverride =
        ConversationFlagsStore.instance.flagsFor(ref).muteOverride;
    await ConversationFlagsStore.instance.setMuteOverride(ref, value);
    unawaited(ChatMuteStatusCache.instance.write(ref.id, value));
    try {
      await _chatMuteService.setMuted(peerId: ref.id, muted: value);
    } catch (e) {
      await ConversationFlagsStore.instance.setMuteOverride(
        ref,
        previousOverride,
      );
      unawaited(
        ChatMuteStatusCache.instance.write(ref.id, previousOverride ?? false),
      );
      debugPrint('[ConversationsCubit] chat_mutes sync failed: $e');
      rethrow;
    }
  }

  Future<void> setMuted(ConversationRef ref, bool value) async {
    try {
      await _applyMuted(ref, value);
    } catch (e) {
      AppToast.error(SupabaseErrorMapper.toUserMessage(e));
    } finally {
      _recompute();
    }
  }

  Future<void> bulkSetPinned(Set<ConversationRef> refs, bool value) async {
    for (final ref in refs) {
      await _applyPinned(ref, value);
    }
    _recompute();
  }

  Future<void> bulkSetFavorite(Set<ConversationRef> refs, bool value) async {
    for (final ref in refs) {
      await _applyFavorite(ref, value);
    }
    _recompute();
  }

  Future<void> bulkSetArchived(Set<ConversationRef> refs, bool value) async {
    for (final ref in refs) {
      await _applyArchived(ref, value);
    }
    _recompute();
  }

  Future<void> bulkSetMuted(Set<ConversationRef> refs, bool value) async {
    var failures = 0;
    for (final ref in refs) {
      try {
        await _applyMuted(ref, value);
      } catch (e) {
        failures++;
        debugPrint('[ConversationsCubit] bulkSetMuted failed for $ref: $e');
      }
    }
    if (failures > 0) {
      AppToast.error(
        failures == refs.length
            ? "Couldn't update mute status. Please try again."
            : 'Updated ${refs.length - failures} of ${refs.length} chats — '
                'some failed. Please try again.',
      );
    }
    _recompute();
  }

  Future<void> _syncGroupMuteWithArchive(
    ConversationRef ref, {
    required bool archiving,
  }) async {
    final group = _rawGroups.firstWhereOrNull((g) => g.id == ref.id);
    if (group == null) return;
    final flags = ConversationFlagsStore.instance.flagsFor(ref);

    if (archiving) {
      if (group.isMuted) return;
      await _setGroupMuteOnBackend(ref.id, true);
      await ConversationFlagsStore.instance.setAutoMutedByArchive(ref, true);
    } else {
      if (!flags.autoMutedByArchive) {
        return;
      }
      await _setGroupMuteOnBackend(ref.id, false);
      await ConversationFlagsStore.instance.setAutoMutedByArchive(ref, false);
    }
  }

  Future<void> _setGroupMuteOnBackend(String groupId, bool muted) async {
    groupListCubit.toggleGroupMute(groupId, muted);
    try {
      await groupChatServices.toggleMute(groupId, muted);
    } catch (e) {
      groupListCubit.toggleGroupMute(groupId, !muted);
      debugPrint('[ConversationsCubit] group mute sync failed: $e');
      rethrow;
    }
  }

  Future<void> _syncSingleChatMuteWithArchive(
    ConversationRef ref, {
    required bool archiving,
  }) async {
    final flags = ConversationFlagsStore.instance.flagsFor(ref);
    if (flags.muteOverride != null) {
      return;
    }
    try {
      await _chatMuteService.setMuted(peerId: ref.id, muted: archiving);
    } catch (e) {
      debugPrint('[ConversationsCubit] chat_mutes sync skipped: $e');
      AppToast.error(
        archiving
            ? "Chat archived, but couldn't mute its notifications automatically."
            : "Chat unarchived, but couldn't restore its notifications automatically.",
      );
    }
  }

  int unreadCountFor(ConversationTab tab) =>
      filtered(tab).fold<int>(0, (sum, item) => sum + item.unreadCount);

  int get archivedUnreadCount {
    final s = state;
    if (s is! ConversationsLoaded) return 0;
    return s.archivedItems.fold<int>(0, (sum, item) => sum + item.unreadCount);
  }

  bool get hasArchivedConversations {
    final s = state;
    if (s is! ConversationsLoaded) return false;
    return s.archivedItems.isNotEmpty;
  }

  @override
  Future<void> close() {
    _chatsSub?.cancel();
    _groupsSub?.cancel();
    if (_chatMutesChannel != null) {
      SupabaseProvider.client.removeChannel(_chatMutesChannel!);
    }
    return super.close();
  }
}
