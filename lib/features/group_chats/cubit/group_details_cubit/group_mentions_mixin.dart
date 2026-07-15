part of 'group_details_cubit.dart';

mixin GroupMentionsMixin on Cubit<GroupDetailsState> {
  GroupChatServices get _services;
  GroupModel get group;
  List<GroupMessageModel> get cachedMessages;
  set cachedMessages(List<GroupMessageModel> value);
  final Map<String, List<MentionRef>> _mentionsCache = {};

  String? get _messagesSnapshotKey;

  void _persistMessagesSnapshot(String key, List<GroupMessageModel> messages);

  void _emitLoaded();
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
      cachedMessages =
          cachedMessages.map((msg) {
            final mentions = _mentionsCache[msg.id] ?? msg.mentions;
            return msg.copyWith(mentions: mentions);
          }).toList();
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
