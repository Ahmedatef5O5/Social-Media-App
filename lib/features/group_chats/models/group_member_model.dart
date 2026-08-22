import '../../../core/utilities/supabase_constants.dart';

enum GroupMemberRole { owner, admin, member }

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
    final groupId = map[GroupMemberColumns.groupId] as String;
    final userId = map[GroupMemberColumns.userId] as String;

    return GroupMemberModel(
      id: (map['id'] as String?) ?? '${groupId}_$userId',
      groupId: map[GroupMemberColumns.groupId] as String,
      userId: map[GroupMemberColumns.userId] as String,
      userName: (map['user_name'] ?? map['name'] ?? 'Unknown') as String,
      userAvatar: map['user_avatar'] as String? ?? map['image_url'] as String?,
      role: switch (map['role'] as String?) {
        'owner' => GroupMemberRole.owner,
        'admin' => GroupMemberRole.admin,
        _ => GroupMemberRole.member,
      },
      joinedAt: DateTime.parse(
        map['joined_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      GroupMemberColumns.groupId: groupId,
      GroupMemberColumns.userId: userId,
      'role': role.name,
      'joined_at': joinedAt.toIso8601String(),
    };
  }
}
