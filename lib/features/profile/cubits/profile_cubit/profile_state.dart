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
  final ProfileMutualsModel mutuals;

  const ProfileLoaded({
    required this.stats,
    required this.user,
    required this.friendsCount,
    required this.mutualFriendsCount,
    required this.friendshipStatus,
    this.friendshipId,
    required this.isFollowing,
    required this.followsMe,
    this.mutuals = ProfileMutualsModel.empty,
  });

  ProfileLoaded copyWith({
    ProfileStatsModel? stats,
    int? friendsCount,
    int? mutualFriendsCount,
    FriendshipStatus? friendshipStatus,
    String? friendshipId,
    bool clearFriendshipId = false,
    bool? isFollowing,
    bool? followsMe,
    ProfileMutualsModel? mutuals,
  }) {
    return ProfileLoaded(
      stats: stats ?? this.stats,
      user: user,
      friendsCount: friendsCount ?? this.friendsCount,
      mutualFriendsCount: mutualFriendsCount ?? this.mutualFriendsCount,
      friendshipStatus: friendshipStatus ?? this.friendshipStatus,
      friendshipId:
          clearFriendshipId ? null : (friendshipId ?? this.friendshipId),
      isFollowing: isFollowing ?? this.isFollowing,
      followsMe: followsMe ?? this.followsMe,
      mutuals: mutuals ?? this.mutuals,
    );
  }
}

final class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);
}
