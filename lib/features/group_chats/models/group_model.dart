import 'package:social_media_app/core/localization/app_l10n.dart';
import 'package:social_media_app/features/group_chats/models/group_member_model.dart';
import 'group_presence_entry.dart';

const _unset = Object();

/// Who may publish posts inside a group (`groups.who_can_post`).
enum GroupWhoCanPost {
  all('all'),
  adminsOnly('admins_only'),

  /// UI label "No one": implicitly only the group owner can publish.
  ownerOnly('owner_only');

  const GroupWhoCanPost(this.dbValue);
  final String dbValue;

  static GroupWhoCanPost fromDb(String? raw) => switch (raw) {
    'admins_only' => GroupWhoCanPost.adminsOnly,
    'owner_only' => GroupWhoCanPost.ownerOnly,
    _ => GroupWhoCanPost.all,
  };

  /// Mirrors `can_post_in_group` for an ACTIVE, non-blocked member.
  bool allows(GroupMemberRole? role) => switch (this) {
    GroupWhoCanPost.all => role != null,
    GroupWhoCanPost.adminsOnly =>
      role == GroupMemberRole.owner || role == GroupMemberRole.admin,
    GroupWhoCanPost.ownerOnly => role == GroupMemberRole.owner,
  };
}

/// Who may send chat messages / start calls (`groups.who_can_send`).
enum GroupWhoCanSend {
  all('all'),
  adminsOnly('admins_only'),

  /// UI label "No one": implicitly only the group owner can send / call.
  ownerOnly('owner_only');

  const GroupWhoCanSend(this.dbValue);
  final String dbValue;

  static GroupWhoCanSend fromDb(String? raw) => switch (raw) {
    'admins_only' => GroupWhoCanSend.adminsOnly,
    'owner_only' => GroupWhoCanSend.ownerOnly,
    _ => GroupWhoCanSend.all,
  };

  /// Mirrors `can_send_in_group` for an ACTIVE, non-blocked member.
  bool allows(GroupMemberRole? role) => switch (this) {
    GroupWhoCanSend.all => role != null,
    GroupWhoCanSend.adminsOnly =>
      role == GroupMemberRole.owner || role == GroupMemberRole.admin,
    GroupWhoCanSend.ownerOnly => role == GroupMemberRole.owner,
  };
}

/// Group discoverability (`groups.privacy`). Existing groups stay private.
enum GroupPrivacy {
  publicGroup('public'),
  privateGroup('private');

  const GroupPrivacy(this.dbValue);
  final String dbValue;

  static GroupPrivacy fromDb(String? raw) =>
      raw == 'public' ? GroupPrivacy.publicGroup : GroupPrivacy.privateGroup;

  bool get isPublic => this == GroupPrivacy.publicGroup;
}

class GroupModel {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? createdBy;
  final DateTime createdAt;
  final bool isMember;
  final List<GroupMemberModel> members;
  final String? lastMessage;
  final String? lastMessageSenderId;
  final String? _lastMessageSenderName;
  final String? lastMessageType;
  final DateTime? lastMessageAt;
  final String? lastMessageTargetId;
  final String? _lastMessageTargetName;
  final int unreadCount;
  final String? title;
  final bool isBlocked;
  final bool isMuted;
  final GroupPresenceSnapshot presence;
  final String? coverUrl;
  final String? description;
  final GroupWhoCanPost whoCanPost;
  final GroupWhoCanSend whoCanSend;
  final GroupPrivacy privacy;

  /// The current user's ACTIVE role in this group (null when not a member).
  final GroupMemberRole? myRole;

  /// Only filled by discovery / global search rows.
  final int? membersCount;

  /// 'pending' when the current user already asked to join (discovery rows).
  final String? myRequestStatus;

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
    String? lastMessageSenderName,
    this.lastMessageType,
    this.lastMessageAt,
    this.lastMessageTargetId,
    String? lastMessageTargetName,
    this.unreadCount = 0,
    this.title,
    this.isBlocked = false,
    this.isMuted = false,
    this.presence = GroupPresenceSnapshot.empty,
    this.coverUrl,
    this.description,
    this.whoCanPost = GroupWhoCanPost.all,
    this.whoCanSend = GroupWhoCanSend.all,
    this.privacy = GroupPrivacy.privateGroup,
    this.myRole,
    this.membersCount,
    this.myRequestStatus,
  }) : _lastMessageSenderName = lastMessageSenderName,
       _lastMessageTargetName = lastMessageTargetName;
  bool get isPublic => privacy.isPublic;
  bool get hasPendingJoinRequest => myRequestStatus == 'pending';

  /// Whether [currentUserId] may send messages / start calls right now.
  /// Mirrors `can_send_in_group` on the server (which stays authoritative).
  bool canSend(String currentUserId) {
    if (!isMember || isBlocked) return false;
    final role =
        myRole ?? (createdBy == currentUserId ? GroupMemberRole.owner : null);
    // Unknown role of an active member: fail OPEN only for the unrestricted
    // policy so a stale cache never locks anyone out of an open group.
    if (role == null) return whoCanSend == GroupWhoCanSend.all;
    return whoCanSend.allows(role);
  }

  String? get lastMessageSenderName =>
      _lastMessageSenderName?.trim().toLowerCase() == 'deleted account'
          ? AppL10n.current.deletedAccount
          : _lastMessageSenderName;
  String? get lastMessageTargetName =>
      _lastMessageTargetName?.trim().toLowerCase() == 'deleted account'
          ? AppL10n.current.deletedAccount
          : _lastMessageTargetName;

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
    bool? isBlocked,
    bool? isMuted,
    GroupPresenceSnapshot? presence,
    Object? coverUrl = _unset,
    Object? description = _unset,
    GroupWhoCanPost? whoCanPost,
    GroupWhoCanSend? whoCanSend,
    GroupPrivacy? privacy,
    Object? myRole = _unset,
    Object? membersCount = _unset,
    Object? myRequestStatus = _unset,
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
      isBlocked: isBlocked ?? this.isBlocked,
      isMuted: isMuted ?? this.isMuted,
      presence: presence ?? this.presence,
      coverUrl:
          identical(coverUrl, _unset) ? this.coverUrl : coverUrl as String?,
      description:
          identical(description, _unset)
              ? this.description
              : description as String?,
      whoCanPost: whoCanPost ?? this.whoCanPost,
      whoCanSend: whoCanSend ?? this.whoCanSend,
      privacy: privacy ?? this.privacy,
      myRole:
          identical(myRole, _unset) ? this.myRole : myRole as GroupMemberRole?,
      membersCount:
          identical(membersCount, _unset)
              ? this.membersCount
              : membersCount as int?,
      myRequestStatus:
          identical(myRequestStatus, _unset)
              ? this.myRequestStatus
              : myRequestStatus as String?,
    );
  }

  static GroupMemberRole? roleFromDb(String? raw) => switch (raw) {
    'owner' => GroupMemberRole.owner,
    'admin' => GroupMemberRole.admin,
    'member' => GroupMemberRole.member,
    _ => null,
  };

  static String? roleToDb(GroupMemberRole? r) => switch (r) {
    GroupMemberRole.owner => 'owner',
    GroupMemberRole.admin => 'admin',
    GroupMemberRole.member => 'member',
    null => null,
  };

  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      id: map['id'],
      name: map['name'] ?? '',
      avatarUrl: map['avatar_url'],
      title: map['title'] as String?,
      createdBy: map['created_by'] as String?,
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
      isBlocked: (map['is_blocked'] as bool?) ?? false,
      isMuted: (map['is_muted'] as bool?) ?? false,
      coverUrl: map['cover_url'] as String?,
      description: map['description'] as String?,
      whoCanPost: GroupWhoCanPost.fromDb(map['who_can_post'] as String?),
      whoCanSend: GroupWhoCanSend.fromDb(map['who_can_send'] as String?),
      privacy: GroupPrivacy.fromDb(map['privacy'] as String?),
      myRole: roleFromDb(map['my_role'] as String?),
      membersCount: (map['members_count'] as num?)?.toInt(),
      myRequestStatus: map['my_request_status'] as String?,
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
    'last_message_sender_name': _lastMessageSenderName,
    'last_message_type': lastMessageType,
    'last_message_at': lastMessageAt?.toIso8601String(),
    'last_message_target_id': lastMessageTargetId,
    'last_message_target_name': _lastMessageTargetName,
    'unread_count': unreadCount,
    'is_muted': isMuted,
    'cover_url': coverUrl,
    'description': description,
    'who_can_post': whoCanPost.dbValue,
    'who_can_send': whoCanSend.dbValue,
    'privacy': privacy.dbValue,
    'my_role': roleToDb(myRole),
    'members_count': membersCount,
    'my_request_status': myRequestStatus,
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
      coverUrl: map['cover_url'] as String?,
      description: map['description'] as String?,
      whoCanPost: GroupWhoCanPost.fromDb(map['who_can_post'] as String?),
      whoCanSend: GroupWhoCanSend.fromDb(map['who_can_send'] as String?),
      privacy: GroupPrivacy.fromDb(map['privacy'] as String?),
      myRole: roleFromDb(map['my_role'] as String?),
      membersCount: (map['members_count'] as num?)?.toInt(),
      myRequestStatus: map['my_request_status'] as String?,
    );
  }
}
