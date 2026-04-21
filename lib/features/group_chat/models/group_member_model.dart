enum GroupMemberRole { admin, member }

class GroupMemberModel {
  final String id;
  final String groupId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final GroupMemberRole role;
  final DateTime joinedAt;

  const GroupMemberModel({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.role,
    required this.joinedAt,
  });

  factory GroupMemberModel.fromMap(Map<String, dynamic> map) {
    return GroupMemberModel(
      id: map['id'] as String,
      groupId: map['group_id'] as String,
      userId: map['user_id'] as String,
      userName: (map['user_name'] ?? map['name'] ?? 'Unknown') as String,
      userAvatar: map['user_avatar'] as String? ?? map['image_url'] as String?,
      role:
          map['role'] == 'admin'
              ? GroupMemberRole.admin
              : GroupMemberRole.member,
      joinedAt: DateTime.parse(
        map['joined_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'group_id': groupId,
      'user_id': userId,
      'role': role.name,
      'joined_at': joinedAt.toIso8601String(),
    };
  }
}
