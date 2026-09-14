import 'package:social_media_app/features/auth/data/models/user_data.dart';
import 'friendship_status.dart';

class DiscoverPersonModel {
  final UserData user;
  final FriendshipStatus friendshipStatus;
  final String? friendshipId;
  final bool isFollowing;
  final bool followsMe;
  final int totalFriendsCount;
  final int mutualFriendsCount;
  final int mutualGroupsCount;
  final List<MutualFriendPreviewModel> mutualFriendsPreview;

  const DiscoverPersonModel({
    required this.user,
    required this.friendshipStatus,
    this.friendshipId,
    required this.isFollowing,
    required this.followsMe,
    required this.totalFriendsCount,
    required this.mutualFriendsCount,
    required this.mutualGroupsCount,
    this.mutualFriendsPreview = const [],
  });

  factory DiscoverPersonModel.fromMap(Map<String, dynamic> map) {
    return DiscoverPersonModel(
      user: UserData.fromMap(map),
      friendshipStatus: friendshipStatusFromString(
        map['friendship_status'] as String?,
      ),
      friendshipId: map['friendship_id'] as String?,
      isFollowing: map['is_following'] as bool? ?? false,
      followsMe: map['follows_me'] as bool? ?? false,
      totalFriendsCount: (map['total_friends_count'] as num?)?.toInt() ?? 0,
      mutualFriendsCount: (map['mutual_friends_count'] as num?)?.toInt() ?? 0,
      mutualGroupsCount: (map['mutual_groups_count'] as num?)?.toInt() ?? 0,
      mutualFriendsPreview:
          (map['mutual_friends_preview'] as List<dynamic>? ?? const [])
              .map(
                (e) =>
                    MutualFriendPreviewModel.fromMap(e as Map<String, dynamic>),
              )
              .toList(),
    );
  }

  DiscoverPersonModel copyWith({
    FriendshipStatus? friendshipStatus,
    bool? isFollowing,
    bool? followsMe,
  }) {
    return DiscoverPersonModel(
      user: user,
      friendshipStatus: friendshipStatus ?? this.friendshipStatus,
      friendshipId: friendshipId,
      isFollowing: isFollowing ?? this.isFollowing,
      followsMe: followsMe ?? this.followsMe,
      totalFriendsCount: totalFriendsCount,
      mutualFriendsCount: mutualFriendsCount,
      mutualGroupsCount: mutualGroupsCount,
      mutualFriendsPreview: mutualFriendsPreview,
    );
  }

  DiscoverPersonModel withFriendshipId(String? id) {
    return DiscoverPersonModel(
      user: user,
      friendshipStatus: friendshipStatus,
      friendshipId: id,
      isFollowing: isFollowing,
      followsMe: followsMe,
      totalFriendsCount: totalFriendsCount,
      mutualFriendsCount: mutualFriendsCount,
      mutualGroupsCount: mutualGroupsCount,
      mutualFriendsPreview: mutualFriendsPreview,
    );
  }
}

class MutualFriendPreviewModel {
  final String id;
  final String? imageUrl;

  const MutualFriendPreviewModel({required this.id, this.imageUrl});

  factory MutualFriendPreviewModel.fromMap(Map<String, dynamic> map) {
    return MutualFriendPreviewModel(
      id: map['id'] as String,
      imageUrl: map['image_url'] as String?,
    );
  }
}
