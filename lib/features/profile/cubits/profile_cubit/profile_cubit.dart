import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/features/auth/data/models/user_data.dart';
import 'package:social_media_app/features/profile/models/profile_mutuals_model.dart';
import 'package:social_media_app/features/profile/models/profile_overview_model.dart';
import 'package:social_media_app/features/profile/models/profile_stats_model.dart';
import 'package:social_media_app/features/social_graph/models/friendship_status.dart';
import '../../../../core/connectivity/cubits/connectivity_cubit.dart';
import '../../../../core/connectivity/cubits/connectivity_state.dart';
import '../../../../core/helpers/safe_emit_mixin.dart';
import '../../../../core/services/fcm_services.dart';
import '../../../../core/supabase/supabase_provider.dart';
import '../../../auth/handlers/auth_exception_handler.dart';
import '../../../home/cubits/home_cubit/home_cubit.dart';
import '../../../notifications/repository/notifications_repository.dart';
import '../../../social_graph/services/follow_services.dart';
import '../../../social_graph/services/friendship_services.dart';
import '../../services/user_services.dart';
part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState>
    with SafeEmitMixin<ProfileState> {
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

  ProfileStatsModel _buildStats(ProfileOverviewModel overview, int mediaCount) {
    return ProfileStatsModel(
      postsCount: overview.postsCount,
      mediaCount: mediaCount,
      followersCount: overview.followersCount,
      followingCount: overview.followingCount,
    );
  }

  ProfileLoaded _buildLoadedState(
    UserData user,
    ProfileOverviewModel overview, {
    ProfileMutualsModel mutuals = ProfileMutualsModel.empty,
    required int mediaCount,
  }) {
    return ProfileLoaded(
      stats: _buildStats(overview, mediaCount),
      user: user,
      friendsCount: overview.friendsCount,
      mutualFriendsCount: overview.mutualFriendsCount,
      friendshipStatus: overview.friendshipStatus,
      friendshipId: overview.friendshipId,
      isFollowing: overview.isFollowing,
      followsMe: overview.followsMe,
      mutuals: mutuals,
    );
  }

  Future<void> getProfileData(String userId, {bool isRefresh = false}) async {
    _currentUserId = userId;
    if (!isRefresh) emit(ProfileLoading());
    try {
      final isOwnProfile = userId == SupabaseProvider.id;
      final results = await Future.wait<Object>([
        _userService.fetchCurrentUser(userId),
        _userService.getProfileOverview(userId),
        isOwnProfile
            ? Future<ProfileMutualsModel>.value(ProfileMutualsModel.empty)
            : _userService.getProfileMutuals(userId),
        _userService.getProfileMediaCount(userId),
      ]);

      final user = results[0] as UserData;
      final overview = results[1] as ProfileOverviewModel;
      final mutuals = results[2] as ProfileMutualsModel;
      final mediaCount = results[3] as int;

      final loaded = _buildLoadedState(
        user,
        overview,
        mutuals: mutuals,
        mediaCount: mediaCount,
      );
      emit(loaded);

      if (isRefresh) {
        emit(ProfileRefreshFeedback());
        await Future.delayed(const Duration(milliseconds: 500));
        emit(loaded);
      }
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

  Future<void> _resyncFromServer(ProfileLoaded fallback) async {
    final userId = _currentUserId;
    if (userId == null) {
      if (!isClosed) emit(fallback);
      return;
    }
    try {
      final overview = await _userService.getProfileOverview(userId);
      if (isClosed) return;
      final current = state;
      final base = current is ProfileLoaded ? current : fallback;
      // Friendship actions never change the mutuals, so keep what we have.
      emit(
        _buildLoadedState(
          base.user,
          overview,
          mutuals: base.mutuals,
          mediaCount: base.stats.mediaCount,
        ),
      );
    } catch (e) {
      debugPrint('[ProfileCubit] resync failed: $e');
      if (!isClosed) emit(fallback);
    }
  }

  /// Runs a side effect (notification / push) that must never roll back a
  /// friendship change that was already persisted in the database.
  Future<void> _runBestEffort(
    String label,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (e) {
      debugPrint('[ProfileCubit] $label failed (non-blocking): $e');
    }
  }

  Future<bool> sendFriendRequest() async {
    if (state is! ProfileLoaded) return false;
    final s = state as ProfileLoaded;
    emit(s.copyWith(friendshipStatus: FriendshipStatus.pendingSent));

    String friendshipId;
    try {
      friendshipId = await _friendshipServices.sendFriendRequest(s.user.id);
    } catch (e) {
      debugPrint('sendFriendRequest error: $e');
      await _resyncFromServer(s);
      return false;
    }

    if (state is ProfileLoaded) {
      emit((state as ProfileLoaded).copyWith(friendshipId: friendshipId));
    }

    final me = _homeCubit.currentUserData;
    if (me != null) {
      unawaited(
        _runBestEffort(
          'notifyFriendRequest',
          () => NotificationRepository.instance.notifyFriendRequest(
            receiverId: s.user.id,
            requesterId: me.id,
            requesterName: me.name,
            requesterImageUrl: me.imageUrl ?? '',
            friendshipId: friendshipId,
          ),
        ),
      );
      unawaited(
        _runBestEffort(
          'fcm notifyFriendRequest',
          () => FcmService.instance.notifyFriendRequest(
            receiverId: s.user.id,
            requesterId: me.id,
            requesterName: me.name,
            requesterImageUrl: me.imageUrl ?? '',
          ),
        ),
      );
    }
    return true;
  }

  Future<void> acceptFriendRequest() async {
    if (state is! ProfileLoaded) return;
    final s = state as ProfileLoaded;

    final friendshipId = s.friendshipId;
    if (friendshipId == null) {
      await _resyncFromServer(s);
      return;
    }

    emit(
      s.copyWith(
        friendshipStatus: FriendshipStatus.accepted,
        friendsCount: s.friendsCount + 1,
      ),
    );

    bool wasAccepted;
    try {
      wasAccepted = await _friendshipServices.acceptFriendRequest(friendshipId);
    } catch (e) {
      debugPrint('acceptFriendRequest error: $e');
      if (!isClosed) emit(s);
      return;
    }

    if (!wasAccepted) {
      // The request was cancelled or already handled elsewhere.
      await _resyncFromServer(s);
      return;
    }

    final me = _homeCubit.currentUserData;
    if (me == null) return;
    await _runBestEffort(
      'removeFriendRequestNotification',
      () => NotificationRepository.instance.removeFriendRequestNotification(
        receiverId: me.id,
        senderId: s.user.id,
      ),
    );
    await _runBestEffort(
      'notifyFriendAccept',
      () => NotificationRepository.instance.notifyFriendAccept(
        receiverId: s.user.id,
        accepterId: me.id,
        accepterName: me.name,
        accepterImageUrl: me.imageUrl ?? '',
      ),
    );
    await _runBestEffort(
      'fcm notifyFriendAccept',
      () => FcmService.instance.notifyFriendAccept(
        receiverId: s.user.id,
        accepterId: me.id,
        accepterName: me.name,
        accepterImageUrl: me.imageUrl ?? '',
      ),
    );
  }

  Future<bool> cancelFriendRequest() async {
    if (state is! ProfileLoaded) return false;
    final s = state as ProfileLoaded;
    final friendshipId = s.friendshipId;
    if (friendshipId == null) return false;

    emit(
      s.copyWith(
        friendshipStatus: FriendshipStatus.none,
        clearFriendshipId: true,
      ),
    );

    try {
      await _friendshipServices.cancelFriendRequest(friendshipId);
    } catch (e) {
      debugPrint('cancelFriendRequest error: $e');
      if (!isClosed) emit(s);
      return false;
    }

    final me = _homeCubit.currentUserData;
    if (me != null) {
      unawaited(
        _runBestEffort(
          'removeFriendRequestNotification',
          () => NotificationRepository.instance.removeFriendRequestNotification(
            receiverId: s.user.id,
            senderId: me.id,
          ),
        ),
      );
    }
    return true;
  }

  /// Declines an incoming friend request (the "X" next to Accept).
  Future<void> declineFriendRequest() async {
    if (state is! ProfileLoaded) return;
    final s = state as ProfileLoaded;
    final friendshipId = s.friendshipId;
    if (friendshipId == null) {
      await _resyncFromServer(s);
      return;
    }

    emit(
      s.copyWith(
        friendshipStatus: FriendshipStatus.none,
        clearFriendshipId: true,
      ),
    );

    try {
      await _friendshipServices.rejectFriendRequest(friendshipId);
    } catch (e) {
      debugPrint('declineFriendRequest error: $e');
      if (!isClosed) emit(s);
      return;
    }

    final me = _homeCubit.currentUserData;
    if (me == null) return;
    await _runBestEffort(
      'removeFriendRequestNotification',
      () => NotificationRepository.instance.removeFriendRequestNotification(
        receiverId: me.id,
        senderId: s.user.id,
      ),
    );
  }

  /// Removes an accepted friend (confirmed by the caller beforehand).
  Future<void> unfriend() async {
    if (state is! ProfileLoaded) return;
    final s = state as ProfileLoaded;
    final friendshipId = s.friendshipId;
    if (friendshipId == null) {
      await _resyncFromServer(s);
      return;
    }

    emit(
      s.copyWith(
        friendshipStatus: FriendshipStatus.none,
        clearFriendshipId: true,
        friendsCount: s.friendsCount > 0 ? s.friendsCount - 1 : 0,
      ),
    );

    try {
      await _friendshipServices.unfriend(friendshipId);
    } catch (e) {
      debugPrint('unfriend error: $e');
      if (!isClosed) emit(s);
    }
  }

  /// Returns `true` when the follow / unfollow was persisted.
  Future<bool> toggleFollow() async {
    if (state is! ProfileLoaded) return false;
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
      } else {
        await _followServices.followUser(s.user.id);
      }
    } catch (e) {
      debugPrint('toggleFollow error: $e');
      if (!isClosed) emit(s);
      return false;
    }

    // The follow row is saved: notifications are best-effort side effects.
    if (me != null) {
      if (wasFollowing) {
        unawaited(
          _runBestEffort(
            'removeFollowNotification',
            () => NotificationRepository.instance.removeFollowNotification(
              receiverId: s.user.id,
              senderId: me.id,
            ),
          ),
        );
      } else {
        unawaited(
          _runBestEffort(
            'notifyFollow',
            () => NotificationRepository.instance.notifyFollow(
              receiverId: s.user.id,
              followerId: me.id,
              followerName: me.name,
              followerImageUrl: me.imageUrl ?? '',
            ),
          ),
        );
        unawaited(
          _runBestEffort(
            'fcm notifyFollow',
            () => FcmService.instance.notifyFollow(
              receiverId: s.user.id,
              followerId: me.id,
              followerName: me.name,
              followerImageUrl: me.imageUrl ?? '',
            ),
          ),
        );
      }
    }
    return true;
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }
}
