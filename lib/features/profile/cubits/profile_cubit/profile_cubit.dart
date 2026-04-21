import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/features/auth/data/models/user_data.dart';
import 'package:social_media_app/features/home/services/home_services.dart';
import 'package:social_media_app/features/profile/models/profile_stats_model.dart';
part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final HomeServices _homeServices;

  ProfileCubit(this._homeServices) : super(ProfileInitial());

  Future<void> getProfileData(String userId, {bool isRefresh = false}) async {
    if (!isRefresh) emit(ProfileLoading());
    try {
      final user = await _homeServices.userServices.fetchCurrentUser(userId);
      final allPosts = await _homeServices.postServices.fetchPosts();
      final userPostsCount = allPosts.where((p) => p.authorId == userId).length;

      final stats = ProfileStatsModel(
        postsCount: userPostsCount,
        photosCount: userPostsCount,
        followersCount: 10500,
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
