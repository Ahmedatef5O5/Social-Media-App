class ForwardTargetSelection {
  final Set<String> userIds;
  final Map<String, String> groups; // groupId -> groupName

  /// True when the user tapped the "AI Assistant" tile in the picker
  /// instead of selecting people/groups. Mutually exclusive with
  /// [userIds]/[groups] in practice — the picker disables normal
  /// multi-select the moment this tile is tapped and pops immediately,
  /// see ForwardTargetPickerView._aiTile.
  final bool toAi;

  const ForwardTargetSelection({
    this.userIds = const {},
    this.groups = const {},
    this.toAi = false,
  });

  bool get isEmpty => userIds.isEmpty && groups.isEmpty && !toAi;
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
