import 'package:social_media_app/features/profile/services/user_services.dart';
import '../../auth/data/models/user_data.dart';
import '../models/profile_stats_model.dart';

class ProfileService {
  final userService = UserService();

  Future<UserData> fetchUser(String userId) {
    return userService.fetchCurrentUser(userId);
  }

  Future<ProfileStatsModel> fetchProfileStats(String userId) async {
    try {
      final overview = await userService.getProfileOverview(userId);
      return ProfileStatsModel(
        postsCount: overview.postsCount,
        mediaCount: overview.postsCount,
        followersCount: overview.followersCount,
        followingCount: overview.followingCount,
      );
    } catch (_) {
      // Fallback: exact count directly from posts table
      final exactCount = await userService.getUserPostsCount(userId);
      return ProfileStatsModel(
        postsCount: exactCount,
        mediaCount: exactCount,
        followersCount: 10500, // temp
        followingCount: 65000, // temp
      );
    }
  }
}
