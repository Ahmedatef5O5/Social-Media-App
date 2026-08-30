import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/features/auth/data/models/user_data.dart';
import 'package:social_media_app/features/profile/models/profile_overview_model.dart';
import 'package:social_media_app/features/profile/models/profile_stats_model.dart';
import 'package:social_media_app/features/social_graph/models/friendship_status.dart';
import '../../../../core/connectivity/cubits/connectivity_cubit.dart';
import '../../../../core/connectivity/cubits/connectivity_state.dart';
import '../../../../core/services/fcm_services.dart';
import '../../../auth/handlers/auth_exception_handler.dart';
import '../../../home/cubits/home_cubit/home_cubit.dart';
import '../../../notifications/repository/notifications_repository.dart';
import '../../../social_graph/services/follow_services.dart';
import '../../../social_graph/services/friendship_services.dart';
import '../../services/user_services.dart';
part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final UserService _userService;
  final FriendshipServices _friendshipServices;
  final FollowServices _followServices;
  final HomeCubit _homeCubit;
  final ConnectivityCubit _connectivityCubit;
  StreamSubscription<ConnectivityState>? _connectivitySubscription;
  String? _currentUserId;

  ProfileCubit(
    this._userService, {
    required FriendshipServices friendshipServices,
    required FollowServices followServices,
    required HomeCubit homeCubit,
    required ConnectivityCubit connectivityCubit,
  }) : _friendshipServices = friendshipServices,
       _followServices = followServices,
       _homeCubit = homeCubit,
       _connectivityCubit = connectivityCubit,
       super(ProfileInitial()) {
    _listenToConnectivityRestoration();
  }

  void _listenToConnectivityRestoration() {
    _connectivitySubscription = _connectivityCubit.stream.listen((
      connectivityState,
    ) {
      final bool isBackOnline =
          connectivityState is ConnectivityRestored ||
          connectivityState is ConnectivityOnline;
      if (isBackOnline && state is ProfileError && _currentUserId != null) {
        debugPrint(
          '[ProfileCubit] Connectivity restored while stuck on error → auto re-fetching profile',
        );
        getProfileData(_currentUserId!);
      }
    });
  }

  Future<void> getProfileData(String userId, {bool isRefresh = false}) async {
    _currentUserId = userId;
    if (!isRefresh) emit(ProfileLoading());
    try {
      final results = await Future.wait([
        _userService.fetchCurrentUser(userId),
        _userService.getProfileOverview(userId),
      ]);

      final user = results[0] as UserData;
      final overview = results[1] as ProfileOverviewModel;

      final stats = ProfileStatsModel(
        postsCount: overview.postsCount,
        photosCount: overview.postsCount,
        followersCount: overview.followersCount,
        followingCount: overview.followingCount,
      );
      if (isRefresh) {
        emit(ProfileRefreshFeedback());
        await Future.delayed(const Duration(milliseconds: 500));
      }
      emit(
        ProfileLoaded(
          stats: stats,
          user: user,
          friendsCount: overview.friendsCount,
          mutualFriendsCount: overview.mutualFriendsCount,
          friendshipStatus: overview.friendshipStatus,
          friendshipId: overview.friendshipId,
          isFollowing: overview.isFollowing,
          followsMe: overview.followsMe,
        ),
      );
    } catch (e) {
      final errorMessage = AuthExceptionHandler.handle(e);

      if (errorMessage == 'no-internet' ||
          e.toString().contains('no-internet')) {
        emit(
          ProfileError("No internet connection. Please check your network."),
        );
      } else {
        emit(ProfileError(errorMessage));
      }
    }
  }

  Future<void> sendFriendRequest() async {
    if (state is! ProfileLoaded) return;
    final s = state as ProfileLoaded;
    emit(s.copyWith(friendshipStatus: FriendshipStatus.pendingSent));
    try {
      final friendshipId = await _friendshipServices.sendFriendRequest(
        s.user.id,
      );
      if (state is ProfileLoaded) {
        emit((state as ProfileLoaded).copyWith(friendshipId: friendshipId));
      }
      final me = _homeCubit.currentUserData;
      if (me != null) {
        await NotificationRepository.instance.notifyFriendRequest(
          receiverId: s.user.id,
          requesterId: me.id,
          requesterName: me.name,
          requesterImageUrl: me.imageUrl ?? '',
          friendshipId: friendshipId,
        );
        await FcmService.instance.notifyFriendRequest(
          receiverId: s.user.id,
          requesterId: me.id,
          requesterName: me.name,
          requesterImageUrl: me.imageUrl ?? '',
        );
      }
    } catch (e) {
      emit(s);
      debugPrint('sendFriendRequest error: $e');
    }
  }

  Future<void> acceptFriendRequest() async {
    if (state is! ProfileLoaded) return;
    final s = state as ProfileLoaded;

    emit(s.copyWith(friendshipStatus: FriendshipStatus.accepted));

    try {
      await _friendshipServices.acceptFriendRequest(s.user.id);

      final me = _homeCubit.currentUserData;
      if (me != null) {
        await NotificationRepository.instance.removeFriendRequestNotification(
          receiverId: me.id,
          senderId: s.user.id,
        );

        await NotificationRepository.instance.notifyFriendAccept(
          receiverId: s.user.id,
          accepterId: me.id,
          accepterName: me.name,
          accepterImageUrl: me.imageUrl ?? '',
        );

        await FcmService.instance.notifyFriendAccept(
          receiverId: s.user.id,
          accepterId: me.id,
          accepterName: me.name,
          accepterImageUrl: me.imageUrl ?? '',
        );
      }
    } catch (e) {
      emit(s);
      debugPrint('acceptFriendRequest error: $e');
    }
  }

  Future<void> cancelFriendRequest() async {
    if (state is! ProfileLoaded) return;
    final s = state as ProfileLoaded;
    if (s.friendshipId == null) return;
    final friendshipId = s.friendshipId!;
    emit(
      s.copyWith(
        friendshipStatus: FriendshipStatus.none,
        clearFriendshipId: true,
      ),
    );
    try {
      await _friendshipServices.cancelFriendRequest(friendshipId);
      final me = _homeCubit.currentUserData;
      if (me != null) {
        await NotificationRepository.instance.removeFriendRequestNotification(
          receiverId: s.user.id,
          senderId: me.id,
        );
      }
    } catch (e) {
      emit(s);
      debugPrint('cancelFriendRequest error: $e');
    }
  }

  Future<void> toggleFollow() async {
    if (state is! ProfileLoaded) return;
    final s = state as ProfileLoaded;
    final wasFollowing = s.isFollowing;
    final me = _homeCubit.currentUserData;

    final rawCount = s.stats.followersCount + (wasFollowing ? -1 : 1);
    final optimisticFollowersCount = rawCount < 0 ? 0 : rawCount;

    emit(
      s.copyWith(
        isFollowing: !wasFollowing,
        stats: s.stats.copyWith(followersCount: optimisticFollowersCount),
      ),
    );

    try {
      if (wasFollowing) {
        await _followServices.unfollowUser(s.user.id);
        if (me != null) {
          await NotificationRepository.instance.removeFollowNotification(
            receiverId: s.user.id,
            senderId: me.id,
          );
        }
      } else {
        await _followServices.followUser(s.user.id);
        final me = _homeCubit.currentUserData;
        if (me != null) {
          await NotificationRepository.instance.notifyFollow(
            receiverId: s.user.id,
            followerId: me.id,
            followerName: me.name,
            followerImageUrl: me.imageUrl ?? '',
          );
          await FcmService.instance.notifyFollow(
            receiverId: s.user.id,
            followerId: me.id,
            followerName: me.name,
            followerImageUrl: me.imageUrl ?? '',
          );
        }
      }
    } catch (e) {
      emit(s);
      debugPrint('toggleFollow error: $e');
    }
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }
}
