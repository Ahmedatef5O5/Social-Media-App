import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/features/auth/data/models/user_data.dart';
import 'package:social_media_app/features/home/services/home_services.dart';
import 'package:social_media_app/features/profile/models/profile_stats_model.dart';
part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit() : super(ProfileInitial());
  final homeServices = HomeServices();
  Future<void> getProfileData(String userId) async {
    emit(ProfileLoading());
    try {
      final user = await homeServices.fetchCurrentUser(userId);
      final allPosts = await homeServices.fetchPosts();
      final userPostsCount = allPosts.where((p) => p.authorId == userId).length;
      final stats = ProfileStatsModel(
        postsCount: userPostsCount,
        photosCount: userPostsCount,
        followersCount: 10500,
        followingCount: 65000,
      );
      emit(ProfileLoaded(stats, user));
    } catch (e) {
      debugPrint("Error in getProfileData: $e");
      emit(ProfileError(e.toString()));
    }
  }
}
