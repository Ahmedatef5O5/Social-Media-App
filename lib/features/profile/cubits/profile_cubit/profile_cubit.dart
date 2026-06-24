import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/features/auth/data/models/user_data.dart';
import 'package:social_media_app/features/profile/models/profile_stats_model.dart';
import '../../services/user_services.dart';
part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final UserService _userService;

  ProfileCubit(this._userService) : super(ProfileInitial());

  Future<void> getProfileData(String userId, {bool isRefresh = false}) async {
    if (!isRefresh) emit(ProfileLoading());
    try {
      final results = await Future.wait([
        _userService.fetchCurrentUser(userId),
        _userService.getUserPostsCount(userId),
      ]);

      final user = results[0] as UserData;
      final postsCount = results[1] as int;

      final stats = ProfileStatsModel(
        postsCount: postsCount,
        photosCount: postsCount,
        followersCount: 10500, // TODO:
        followingCount: 65000,
      );
      if (isRefresh) {
        emit(ProfileRefreshFeedback());
        await Future.delayed(const Duration(milliseconds: 500));
      }
      emit(ProfileLoaded(stats, user));
    } catch (e) {
      debugPrint("Error in getProfileData: $e");
      String errorMessage = e.toString().replaceAll('Exception:', '').trim();
      emit(ProfileError(errorMessage));
    }
  }
}
