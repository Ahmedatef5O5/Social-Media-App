import 'package:social_media_app/features/profile/services/user_services.dart';

import '../../auth/data/models/user_data.dart';
import '../../home/services/posts_services.dart';
import '../models/profile_stats_model.dart';

class ProfileService {
  final userService = UserService();
  final postsService = PostsServices();

  Future<UserData> fetchUser(String userId) {
    return userService.fetchCurrentUser(userId);
  }

  Future<ProfileStatsModel> fetchProfileStats(String userId) async {
    final allPosts = await postsService.fetchPosts();
    final userPostsCount = allPosts.where((p) => p.authorId == userId).length;

    return ProfileStatsModel(
      postsCount: userPostsCount,
      photosCount: userPostsCount,
      followersCount: 10500, // temp
      followingCount: 65000, // temp
    );
  }
}
