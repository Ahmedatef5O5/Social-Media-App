import 'group_member_model.dart';
import 'group_model.dart';

enum GroupJoinRequestStatus {
  none,
  pending,
  accepted,
  rejected;

  static GroupJoinRequestStatus fromDb(String? raw) => switch (raw) {
    'pending' => GroupJoinRequestStatus.pending,
    'accepted' => GroupJoinRequestStatus.accepted,
    'rejected' => GroupJoinRequestStatus.rejected,
    _ => GroupJoinRequestStatus.none,
  };
}

/// Result of `get_group_profile`: everything the group profile / preview
/// screens need in one round trip, for members and non-members alike.
class GroupProfileModel {
  final String id;
  final String name;
  final String? title;
  final String? description;
  final String? avatarUrl;
  final String? coverUrl;
  final DateTime createdAt;
  final String? createdBy;
  final String? creatorName;
  final GroupWhoCanPost whoCanPost;
  final int membersCount;
  final int postsCount;
  final int mediaCount;
  final bool isMember;
  final GroupMemberRole? myRole;
  final GroupJoinRequestStatus requestStatus;
  final int pendingRequestsCount;

  const GroupProfileModel({
    required this.id,
    required this.name,
    this.title,
    this.description,
    this.avatarUrl,
    this.coverUrl,
    required this.createdAt,
    this.createdBy,
    this.creatorName,
    this.whoCanPost = GroupWhoCanPost.all,
    this.membersCount = 0,
    this.postsCount = 0,
    this.mediaCount = 0,
    this.isMember = false,
    this.myRole,
    this.requestStatus = GroupJoinRequestStatus.none,
    this.pendingRequestsCount = 0,
  });

  bool get isOwner => isMember && myRole == GroupMemberRole.owner;
  bool get isAdmin => isMember && myRole == GroupMemberRole.admin;
  bool get hasAdminPrivileges => isOwner || isAdmin;

  /// Mirrors `can_post_in_group` on the server.
  bool get canPost =>
      isMember && (whoCanPost == GroupWhoCanPost.all || hasAdminPrivileges);

  factory GroupProfileModel.fromMap(Map<String, dynamic> map) {
    int n(String k) => (map[k] as num?)?.toInt() ?? 0;
    return GroupProfileModel(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      title: map['title'] as String?,
      description: map['description'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      coverUrl: map['cover_url'] as String?,
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      createdBy: map['created_by'] as String?,
      creatorName: map['creator_name'] as String?,
      whoCanPost: GroupWhoCanPost.fromDb(map['who_can_post'] as String?),
      membersCount: n('members_count'),
      postsCount: n('posts_count'),
      mediaCount: n('media_count'),
      isMember: map['is_member'] as bool? ?? false,
      myRole: switch (map['my_role'] as String?) {
        'owner' => GroupMemberRole.owner,
        'admin' => GroupMemberRole.admin,
        'member' => GroupMemberRole.member,
        _ => null,
      },
      requestStatus: GroupJoinRequestStatus.fromDb(
        map['my_request_status'] as String?,
      ),
      pendingRequestsCount: n('pending_requests_count'),
    );
  }

  GroupProfileModel copyWith({
    String? name,
    Object? title = _unset,
    Object? description = _unset,
    Object? avatarUrl = _unset,
    Object? coverUrl = _unset,
    GroupWhoCanPost? whoCanPost,
    int? membersCount,
    int? postsCount,
    int? mediaCount,
    bool? isMember,
    GroupJoinRequestStatus? requestStatus,
    int? pendingRequestsCount,
  }) {
    return GroupProfileModel(
      id: id,
      name: name ?? this.name,
      title: identical(title, _unset) ? this.title : title as String?,
      description:
          identical(description, _unset)
              ? this.description
              : description as String?,
      avatarUrl:
          identical(avatarUrl, _unset) ? this.avatarUrl : avatarUrl as String?,
      coverUrl:
          identical(coverUrl, _unset) ? this.coverUrl : coverUrl as String?,
      createdAt: createdAt,
      createdBy: createdBy,
      creatorName: creatorName,
      whoCanPost: whoCanPost ?? this.whoCanPost,
      membersCount: membersCount ?? this.membersCount,
      postsCount: postsCount ?? this.postsCount,
      mediaCount: mediaCount ?? this.mediaCount,
      isMember: isMember ?? this.isMember,
      myRole: myRole,
      requestStatus: requestStatus ?? this.requestStatus,
      pendingRequestsCount: pendingRequestsCount ?? this.pendingRequestsCount,
    );
  }

  /// Lightweight [GroupModel] used to open the existing chat / settings screens.
  GroupModel toGroupModel() => GroupModel(
    id: id,
    name: name,
    avatarUrl: avatarUrl,
    createdBy: createdBy,
    createdAt: createdAt,
    isMember: isMember,
    title: title,
    coverUrl: coverUrl,
    description: description,
    whoCanPost: whoCanPost,
  );
}

const Object _unset = Object();
