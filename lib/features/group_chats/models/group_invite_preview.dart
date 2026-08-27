class GroupInvitePreview {
  final bool isValid;
  final String? groupId;
  final String? groupName;
  final String? groupTitle;
  final String? groupAvatarUrl;
  final int memberCount;
  final bool isAlreadyMember;

  const GroupInvitePreview({
    required this.isValid,
    this.groupId,
    this.groupName,
    this.groupTitle,
    this.groupAvatarUrl,
    required this.memberCount,
    required this.isAlreadyMember,
  });

  factory GroupInvitePreview.fromMap(Map<String, dynamic> map) {
    return GroupInvitePreview(
      isValid: map['is_valid'] as bool? ?? false,
      groupId: map['group_id'] as String?,
      groupName: map['group_name'] as String?,
      groupTitle: map['group_title'] as String?,
      groupAvatarUrl: map['group_avatar_url'] as String?,
      memberCount: (map['member_count'] as num?)?.toInt() ?? 0,
      isAlreadyMember: map['is_already_member'] as bool? ?? false,
    );
  }
}
