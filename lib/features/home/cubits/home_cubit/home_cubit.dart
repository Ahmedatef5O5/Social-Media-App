import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:social_media_app/core/services/network_status_service.dart';
import 'package:social_media_app/core/cache/constants/snapshot_keys.dart';
import 'package:social_media_app/core/cache/services/local_snapshot_store.dart';
import 'package:social_media_app/features/auth/data/models/user_data.dart';
import '../../../../core/connectivity/services/connectivity_banner_controller.dart';
import '../../../../core/supabase/supabase_provider.dart';
import '../../../posts/cubit/posts_cubit.dart';
import '../../../profile/services/user_services.dart';
part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final UserService _userService;
  final PostsCubit _postsCubit;
  // ignore: unused_field
  final NetworkStatusService _networkStatus;

  HomeCubit({
    required UserService userService,
    NetworkStatusService? networkStatus,
    required PostsCubit postsCubit,
  }) : _userService = userService,
       _postsCubit = postsCubit,
       _networkStatus = networkStatus ?? NetworkStatusService.instance,
       super(HomeInitial());

  UserData? currentUserData;
  PersistentTabController? navController;

  // ── Home data ──────────────────────────────────────────────────────────────

  Future<void> getCurrentUserData({bool isRefresh = false}) async {
    if (!isRefresh) emit(UserDataLoading());
    final userId = SupabaseProvider.id;
    await _getCurrentUser(userId, isRefresh: isRefresh);
  }

  Future<void> refreshUserData({bool isRefresh = false}) async {
    try {
      await getCurrentUserData(isRefresh: isRefresh);
    } catch (e) {
      debugPrint('Error refreshing user data: $e');
      if (e.toString().contains('no-internet')) {
        ConnectivityBannerController.notifyBlockedByOffline();
      }
      if (currentUserData == null) {
        emit(
          UserDataLoadError(
            e.toString().contains('no-internet')
                ? 'No internet connection. Please check your network.'
                : 'An error occurred while updating the data. Please try again.',
          ),
        );
      }
    }
  }

  Future<void> _getCurrentUser(String userId, {bool isRefresh = false}) async {
    try {
      currentUserData = await _userService.fetchCurrentUser(userId);
      if (!isRefresh) emit(UserDataLoaded(currentUserData!));
      _persistCurrentUserSnapshot(currentUserData!);
      _postsCubit.setCurrentUser(currentUserData!);
    } catch (e) {
      debugPrint("Error fetching user: $e");
      if (currentUserData != null) return;
      final diskUser = _readCurrentUserSnapshot();
      if (diskUser != null) {
        debugPrint('Silent error: no internet, showing cached user from disk.');

        currentUserData = diskUser;
        emit(UserDataLoaded(diskUser));
        _postsCubit.setCurrentUser(diskUser);
        return;
      }

      emit(UserDataLoadError(e.toString()));
    }
  }

  void _persistCurrentUserSnapshot(UserData user) {
    unawaited(
      LocalSnapshotStore.instance.saveObject(
        SnapshotKeys.currentUser,
        user.toCacheJson(),
      ),
    );
  }

  UserData? _readCurrentUserSnapshot() {
    try {
      final map = LocalSnapshotStore.instance.readObject(
        SnapshotKeys.currentUser,
      );
      return map != null ? UserData.fromCacheJson(map) : null;
    } catch (e) {
      debugPrint('Failed to read current user snapshot from disk: $e');
      return null;
    }
  }
}
