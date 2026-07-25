class ForwardTargetSelection {
  final Set<String> userIds;
  final Map<String, String> groups; // groupId -> groupName

  const ForwardTargetSelection({
    this.userIds = const {},
    this.groups = const {},
  });

  bool get isEmpty => userIds.isEmpty && groups.isEmpty;
  int get length => userIds.length + groups.length;
}

/// A single row in the picker — either a person (from ConnectionsService)
/// or a joined group (from GroupChatServices.getMyGroups()).
class ForwardTarget {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool isGroup;

  const ForwardTarget({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.isGroup,
  });
}
