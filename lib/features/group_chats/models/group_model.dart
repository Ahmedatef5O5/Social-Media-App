import 'package:social_media_app/features/group_chats/models/group_member_model.dart';

const _unset = Object();

class GroupModel {
  final String id;
  final String name;
  final String? avatarUrl;
  final String createdBy;
  final DateTime createdAt;
  final bool isMember;
  final List<GroupMemberModel> members;
  final String? lastMessage;
  final String? lastMessageSenderId;
  final String? lastMessageSenderName;
  final String? lastMessageType;
  final DateTime? lastMessageAt;
  final String? lastMessageTargetId;
  final String? lastMessageTargetName;
  final int unreadCount;
  final String? title;
  final bool isMuted;

  const GroupModel({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.createdBy,
    required this.createdAt,
    this.isMember = true,
    this.members = const [],
    this.lastMessage,
    this.lastMessageSenderId,
    this.lastMessageSenderName,
    this.lastMessageType,
    this.lastMessageAt,
    this.lastMessageTargetId,
    this.lastMessageTargetName,
    this.unreadCount = 0,
    this.title,
    this.isMuted = false,
  });

  GroupModel copyWith({
    String? id,
    String? name,
    Object? avatarUrl = _unset,
    Object? title = _unset,
    String? createdBy,
    DateTime? createdAt,
    bool? isMember,
    List<GroupMemberModel>? members,
    String? lastMessage,
    String? lastMessageSenderId,
    String? lastMessageSenderName,
    String? lastMessageType,
    DateTime? lastMessageAt,
    String? lastMessageTargetId,
    String? lastMessageTargetName,
    int? unreadCount,
    bool? isMuted,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl:
          identical(avatarUrl, _unset) ? this.avatarUrl : avatarUrl as String?,
      title: identical(title, _unset) ? this.title : title as String?,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      isMember: isMember ?? this.isMember,
      members: members ?? this.members,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageSenderName:
          lastMessageSenderName ?? this.lastMessageSenderName,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessageTargetId: lastMessageTargetId ?? this.lastMessageTargetId,
      lastMessageTargetName:
          lastMessageTargetName ?? this.lastMessageTargetName,
      unreadCount: unreadCount ?? this.unreadCount,
      isMuted: isMuted ?? this.isMuted,
    );
  }

  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      id: map['id'],
      name: map['name'] ?? '',
      avatarUrl: map['avatar_url'],
      title: map['title'] as String?,
      createdBy: map['created_by'] as String,
      createdAt:
          DateTime.tryParse((map['created_at']) as String? ?? '') ??
          DateTime.now(),
      isMember: (map['is_member'] as bool?) ?? true,
      lastMessage: map['last_message'] ?? '',
      lastMessageSenderId: map['last_message_sender_id'],
      lastMessageSenderName: map['last_message_sender_name'],
      lastMessageType: map['last_message_type'] ?? 'text',
      lastMessageAt:
          map['last_message_at'] != null
              ? DateTime.parse(map['last_message_at'])
              : null,
      lastMessageTargetId: map['last_message_target_id'] as String?,
      lastMessageTargetName: map['last_message_target_name'] as String?,
      unreadCount: (map['unread_count'] as int?) ?? 0,
      isMuted: (map['is_muted'] as bool?) ?? false,
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

  Map<String, dynamic> toCacheJson() => {
    'id': id,
    'name': name,
    'avatar_url': avatarUrl,
    'title': title,
    'created_by': createdBy,
    'created_at': createdAt.toIso8601String(),
    'is_member': isMember,
    'last_message': lastMessage,
    'last_message_sender_id': lastMessageSenderId,
    'last_message_sender_name': lastMessageSenderName,
    'last_message_type': lastMessageType,
    'last_message_at': lastMessageAt?.toIso8601String(),
    'last_message_target_id': lastMessageTargetId,
    'last_message_target_name': lastMessageTargetName,
    'unread_count': unreadCount,
    'is_muted': isMuted,
  };

  factory GroupModel.fromCacheJson(Map<String, dynamic> map) {
    return GroupModel(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      avatarUrl: map['avatar_url'] as String?,
      title: map['title'] as String?,
      createdBy: map['created_by'] as String? ?? '',
      createdAt:
          map['created_at'] != null
              ? DateTime.parse(map['created_at'] as String)
              : DateTime.now(),
      isMember: map['is_member'] as bool? ?? true,

      lastMessage: map['last_message'] as String?,
      lastMessageSenderId: map['last_message_sender_id'] as String?,
      lastMessageSenderName: map['last_message_sender_name'] as String?,
      lastMessageType: map['last_message_type'] as String?,
      lastMessageAt:
          map['last_message_at'] != null
              ? DateTime.parse(map['last_message_at'] as String)
              : null,
      lastMessageTargetId: map['last_message_target_id'] as String?,
      lastMessageTargetName: map['last_message_target_name'] as String?,
      unreadCount: (map['unread_count'] as num?)?.toInt() ?? 0,
      isMuted: map['is_muted'] as bool? ?? false,
    );
  }
}
