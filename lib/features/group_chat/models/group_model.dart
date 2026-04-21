import 'package:social_media_app/features/group_chat/models/group_member_model.dart';

class GroupModel {
  final String id;
  final String name;
  final String? avatarUrl;
  final String createdBy;
  final DateTime createdAt;
  final List<GroupMemberModel> members;

  // last message preview (populated by RPC)
  final String? lastMessage;
  final String? lastMessageType;
  final DateTime? lastMessageAt;
  final int unreadCount;

  const GroupModel({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.createdBy,
    required this.createdAt,
    this.members = const [],
    this.lastMessage,
    this.lastMessageType,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  GroupModel copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    String? createdBy,
    DateTime? createdAt,
    List<GroupMemberModel>? members,
    String? lastMessage,
    String? lastMessageType,
    DateTime? lastMessageAt,
    int? unreadCount,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      members: members ?? this.members,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      id: map['id'],
      name: map['name'] ?? '',
      avatarUrl: map['avatar_url'],
      createdBy: map['created_by'] as String,

      createdAt: DateTime.parse(map['group_created_at'] as String),
      lastMessage: map['last_message'] ?? '',
      lastMessageType: map['last_message_type'] ?? 'text',
      lastMessageAt:
          map['last_message_at'] != null
              ? DateTime.parse(map['last_message_at'])
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
