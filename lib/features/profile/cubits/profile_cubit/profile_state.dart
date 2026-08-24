part of 'profile_cubit.dart';

sealed class ProfileState {
  const ProfileState();
}

final class ProfileInitial extends ProfileState {}

final class ProfileRefreshFeedback extends ProfileState {}

final class ProfileLoading extends ProfileState {}

final class ProfileLoaded extends ProfileState {
  final ProfileStatsModel stats;
  final UserData user;
  final int friendsCount;
  final int mutualFriendsCount;
  final FriendshipStatus friendshipStatus;
  final String? friendshipId;
  final bool isFollowing;
  final bool followsMe;

  const ProfileLoaded({
    required this.stats,
    required this.user,
    required this.friendsCount,
    required this.mutualFriendsCount,
    required this.friendshipStatus,
    this.friendshipId,
    required this.isFollowing,
    required this.followsMe,
  });

  ProfileLoaded copyWith({
    ProfileStatsModel? stats,
    FriendshipStatus? friendshipStatus,
    String? friendshipId,
    bool clearFriendshipId = false,
    bool? isFollowing,
  }) {
    return ProfileLoaded(
      stats: stats ?? this.stats,
      user: user,
      friendsCount: friendsCount,
      mutualFriendsCount: mutualFriendsCount,
      friendshipStatus: friendshipStatus ?? this.friendshipStatus,
      friendshipId:
          clearFriendshipId ? null : (friendshipId ?? this.friendshipId),
      isFollowing: isFollowing ?? this.isFollowing,
      followsMe: followsMe,
    );
  }
}

final class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);
}
