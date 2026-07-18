import 'package:social_media_app/features/auth/data/models/user_data.dart';
import 'friendship_status.dart';

class DiscoverPersonModel {
  final UserData user;
  final FriendshipStatus friendshipStatus;
  final String? friendshipId;
  final bool isFollowing;
  final bool followsMe;

  const DiscoverPersonModel({
    required this.user,
    required this.friendshipStatus,
    this.friendshipId,
    required this.isFollowing,
    required this.followsMe,
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
    );
  }

  DiscoverPersonModel withFriendshipId(String? id) {
    return DiscoverPersonModel(
      user: user,
      friendshipStatus: friendshipStatus,
      friendshipId: id,
      isFollowing: isFollowing,
      followsMe: followsMe,
    );
  }
}
