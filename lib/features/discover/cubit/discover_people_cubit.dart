import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/features/discover/services/discover_people_services.dart';
import 'package:social_media_app/features/social_graph/models/discover_person_model.dart';
import '../../../core/services/fcm_services.dart';
import '../../home/cubits/home_cubit/home_cubit.dart';
import '../../notifications/repository/notifications_repository.dart';
import '../../social_graph/models/friendship_status.dart';
import '../../social_graph/services/follow_services.dart';
import '../../social_graph/services/friendship_services.dart';
part 'discover_people_state.dart';

class DiscoverPeopleCubit extends Cubit<DiscoverPeopleState> {
  final DiscoverPeopleServices _discoverPeopleServices;
  final FriendshipServices _friendshipServices;
  final FollowServices _followServices;
  final HomeCubit _homeCubit;

  DiscoverPeopleCubit(
    this._discoverPeopleServices, {
    required FriendshipServices friendshipServices,
    required FollowServices followServices,
    required HomeCubit homeCubit,
  }) : _friendshipServices = friendshipServices,
       _followServices = followServices,
       _homeCubit = homeCubit,
       super(DiscoverPeopleInitial());

  int _currentPage = 0;
  bool _hasReachedMax = false;
  bool _isFetchingMore = false;
  final List<DiscoverPersonModel> _users = [];

  Future<List<DiscoverPersonModel>> getDiscoverPeople({
    bool isRefresh = false,
  }) async {
    if (isRefresh) {
      _currentPage = 0;
      _hasReachedMax = false;
      _users.clear();
      emit(DiscoverPeopleLoading());
    } else if (_currentPage == 0) {
      emit(DiscoverPeopleLoading());
    }

    if (_hasReachedMax || _isFetchingMore) return _users;
    _isFetchingMore = true;

    try {
      final start = DateTime.now();

      final users = await _discoverPeopleServices.getAllUsers(
        page: _currentPage,
        pageSize: 15,
      );

      if (users.isEmpty || users.length < 15) {
        _hasReachedMax = true;
      }

      _users.addAll(users);
      _currentPage++;
      _isFetchingMore = false;

      if (isRefresh) {
        emit(DiscoverPeopleRefreshFeedback());

        final elapsed = DateTime.now().difference(start);
        if (elapsed < const Duration(milliseconds: 600)) {
          await Future.delayed(const Duration(milliseconds: 600) - elapsed);
        }
      }

      emit(
        DiscoverPeopleSuccess(
          users: List.from(_users),
          hasReachedMax: _hasReachedMax,
        ),
      );
      return _users;
    } catch (e) {
      _isFetchingMore = false;

      if (e.toString().contains('no-internet')) {
        emit(
          DiscoverPeopleFailure(
            "No internet connection. Please check your network.",
          ),
        );
      } else {
        emit(
          DiscoverPeopleFailure(
            "Something went wrong. Please try again later.",
          ),
        );
      }
      debugPrint('Error in getDiscoverPeople: $e');
      return _users;
    }
  }

  void _emitUsers() => emit(
    DiscoverPeopleSuccess(
      users: List.from(_users),
      hasReachedMax: _hasReachedMax,
    ),
  );

  void _updateUser(
    String userId,
    DiscoverPersonModel Function(DiscoverPersonModel) update,
  ) {
    final idx = _users.indexWhere((u) => u.user.id == userId);
    if (idx == -1) return;
    _users[idx] = update(_users[idx]);
    _emitUsers();
  }

  Future<void> sendFriendRequest(String userId) async {
    _updateUser(
      userId,
      (u) => u.copyWith(friendshipStatus: FriendshipStatus.pendingSent),
    );
    try {
      final friendshipId = await _friendshipServices.sendFriendRequest(userId);
      _updateUser(userId, (u) => u.withFriendshipId(friendshipId));

      final me = _homeCubit.currentUserData;
      if (me != null) {
        await NotificationRepository.instance.notifyFriendRequest(
          receiverId: userId,
          requesterId: me.id,
          requesterName: me.name,
          requesterImageUrl: me.imageUrl ?? '',
          friendshipId: friendshipId,
        );
        await FcmService.instance.notifyFriendRequest(
          receiverId: userId,
          requesterId: me.id,
          requesterName: me.name,
          requesterImageUrl: me.imageUrl ?? '',
        );
      }
    } catch (e) {
      _updateUser(
        userId,
        (u) => u
            .copyWith(friendshipStatus: FriendshipStatus.none)
            .withFriendshipId(null),
      );
      debugPrint('sendFriendRequest error: $e');
      rethrow;
    }
  }

  Future<void> acceptFriendRequest(String userId) async {
    _updateUser(
      userId,
      (u) => u.copyWith(friendshipStatus: FriendshipStatus.accepted),
    );

    try {
      await _friendshipServices.acceptFriendRequest(userId);
      final me = _homeCubit.currentUserData;
      if (me != null) {
        await NotificationRepository.instance.removeFriendRequestNotification(
          receiverId: me.id,
          senderId: userId,
        );

        await NotificationRepository.instance.notifyFriendAccept(
          receiverId: userId,
          accepterId: me.id,
          accepterName: me.name,
          accepterImageUrl: me.imageUrl ?? '',
        );
        await FcmService.instance.notifyFriendAccept(
          receiverId: userId,
          accepterId: me.id,
          accepterName: me.name,
          accepterImageUrl: me.imageUrl ?? '',
        );
      }
    } catch (e) {
      _updateUser(
        userId,
        (u) => u.copyWith(friendshipStatus: FriendshipStatus.pendingReceived),
      );
      debugPrint('acceptFriendRequest error: $e');
      rethrow;
    }
  }

  Future<void> cancelFriendRequest(String userId, String friendshipId) async {
    _updateUser(
      userId,
      (u) => u
          .copyWith(friendshipStatus: FriendshipStatus.none)
          .withFriendshipId(null),
    );
    try {
      await _friendshipServices.cancelFriendRequest(friendshipId);
      final me = _homeCubit.currentUserData;
      if (me != null) {
        await NotificationRepository.instance.removeFriendRequestNotification(
          receiverId: userId,
          senderId: me.id,
        );
      }
    } catch (e) {
      _updateUser(
        userId,
        (u) => u
            .copyWith(friendshipStatus: FriendshipStatus.pendingSent)
            .withFriendshipId(friendshipId),
      );
      debugPrint('cancelFriendRequest error: $e');
      rethrow;
    }
  }

  Future<void> toggleFollow(
    String userId, {
    required bool isCurrentlyFollowing,
  }) async {
    _updateUser(userId, (u) => u.copyWith(isFollowing: !isCurrentlyFollowing));
    final me = _homeCubit.currentUserData;
    try {
      if (isCurrentlyFollowing) {
        await _followServices.unfollowUser(userId);
        if (me != null) {
          await NotificationRepository.instance.removeFollowNotification(
            receiverId: userId,
            senderId: me.id,
          );
        }
      } else {
        await _followServices.followUser(userId);
        final me = _homeCubit.currentUserData;
        if (me != null) {
          await NotificationRepository.instance.notifyFollow(
            receiverId: userId,
            followerId: me.id,
            followerName: me.name,
            followerImageUrl: me.imageUrl ?? '',
          );
          await FcmService.instance.notifyFollow(
            receiverId: userId,
            followerId: me.id,
            followerName: me.name,
            followerImageUrl: me.imageUrl ?? '',
          );
        }
      }
    } catch (e) {
      _updateUser(userId, (u) => u.copyWith(isFollowing: isCurrentlyFollowing));
      debugPrint('toggleFollow error: $e');
      rethrow;
    }
  }
}
