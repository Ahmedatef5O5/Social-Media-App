part of 'group_details_cubit.dart';

mixin GroupMentionsMixin on Cubit<GroupDetailsState> {
  GroupChatServices get _services;
  GroupModel get group;
  List<GroupMessageModel> get cachedMessages;
  set cachedMessages(List<GroupMessageModel> value);
  final Map<String, List<MentionRef>> _mentionsCache = {};

  String? get _messagesSnapshotKey;

  void _persistMessagesSnapshot(String key, List<GroupMessageModel> messages);

  void _emitLoaded({bool force = false});
  StreamSubscription? _mentionsSubscription;

  void _listenMentions() {
    _mentionsSubscription?.cancel();
    _mentionsSubscription = _services.getMentionsStream(group.id).listen((
      mentionsList,
    ) {
      _mentionsCache.clear();
      for (final m in mentionsList) {
        final msgId = m[GroupMessageMentionColumns.groupMessageId] as String?;
        if (msgId == null) continue;
        _mentionsCache[msgId] ??= [];
        _mentionsCache[msgId]!.add(MentionRef.fromMap(m));
      }
      cachedMessages = GroupDetailsCubit._reconciler.applyFieldUpdate(
        cachedMessages,
        (msg) => msg.copyWith(mentions: _mentionsCache[msg.id] ?? msg.mentions),
      );
      _emitLoaded();
      if (_messagesSnapshotKey != null) {
        _persistMessagesSnapshot(_messagesSnapshotKey!, cachedMessages);
      }
    });
  }

  @override
  Future<void> close() {
    _mentionsSubscription?.cancel();
    return super.close();
  }
}
