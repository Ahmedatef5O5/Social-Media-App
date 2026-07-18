import '../../social_graph/models/friendship_status.dart';

class ProfileOverviewModel {
  final int postsCount;
  final int followersCount;
  final int followingCount;
  final int friendsCount;
  final FriendshipStatus friendshipStatus;
  final String? friendshipId;
  final bool isFollowing;
  final bool followsMe;

  const ProfileOverviewModel({
    required this.postsCount,
    required this.followersCount,
    required this.followingCount,
    required this.friendsCount,
    required this.friendshipStatus,
    this.friendshipId,
    required this.isFollowing,
    required this.followsMe,
  });

  factory ProfileOverviewModel.fromMap(Map<String, dynamic> map) {
    return ProfileOverviewModel(
      postsCount: (map['posts_count'] as num?)?.toInt() ?? 0,
      followersCount: (map['followers_count'] as num?)?.toInt() ?? 0,
      followingCount: (map['following_count'] as num?)?.toInt() ?? 0,
      friendsCount: (map['friends_count'] as num?)?.toInt() ?? 0,
      friendshipStatus: friendshipStatusFromString(
        map['friendship_status'] as String?,
      ),
      friendshipId: map['friendship_id'] as String?,
      isFollowing: map['is_following'] as bool? ?? false,
      followsMe: map['follows_me'] as bool? ?? false,
    );
  }
}
