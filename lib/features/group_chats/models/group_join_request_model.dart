class GroupJoinRequestModel {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final DateTime createdAt;

  const GroupJoinRequestModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.createdAt,
  });

  factory GroupJoinRequestModel.fromMap(Map<String, dynamic> map) {
    return GroupJoinRequestModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      userName: map['user_name'] as String? ?? '',
      userAvatar: map['user_avatar'] as String?,
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
