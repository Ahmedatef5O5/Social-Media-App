part of 'group_list_cubit.dart';

abstract class GroupListBase extends Cubit<GroupListState> {
  final GroupChatServices services;

  RealtimeChannel? channel;
  StreamSubscription? messagesStreamSub;
  StreamSubscription? presenceSub;
  List<GroupModel> cached = [];
  final Map<String, List<GroupMemberModel>> membersByGroupId = {};
  Timer? activeGroupTimer;
  String? activeGroupId;
  int loadGroupsRequestId = 0;
  Timer? reconcileDebounce;
  final Set<String> locallyDeletedGroupIds = {};

  String get currentUserId => SupabaseProvider.id;

  GroupListBase(this.services) : super(GroupListInitial());

  bool isHiddenByLocalClear(GroupModel g) {
    final clearedAt = GroupChatClearStore.instance.clearedAtFor(g.id);
    if (clearedAt == null) return false;
    final lastMsgAt = g.lastMessageAt;
    if (lastMsgAt != null && lastMsgAt.isAfter(clearedAt)) {
      return false;
    }
    return true;
  }

  Future<void> loadGroups({bool isRefresh = false});
  void persistGroupsSnapshot(List<GroupModel> groups);
  void scheduleReconcile();
  void markGroupAsActive(String groupId);
  void markGroupAsLeft(String groupId);
  void removeGroupFromState(String groupId);
  void updateGroupAvatarInState({
    required String groupId,
    String? name,
    String? avatarUrl,
  });
  void updateGroupInState({
    required String groupId,
    required String lastMessage,
    required String lastMessageType,
    required DateTime lastMessageAt,
    String? lastMessageSenderId,
    String? lastMessageSenderName,
    String? lastMessageTargetId,
    String? lastMessageTargetName,
    required int unreadCount,
  });
}
