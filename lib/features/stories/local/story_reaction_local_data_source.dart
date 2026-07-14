import 'package:social_media_app/core/cache/services/hive_cache_manager.dart';

class StoryReactionLocalDataSource {
  StoryReactionLocalDataSource._();

  static final StoryReactionLocalDataSource instance =
      StoryReactionLocalDataSource._();

  String? getCachedReaction(String storyId) {
    return HiveCacheManager.instance.storyReactionsBox.get(storyId);
  }

  Future<void> setCachedReaction(String storyId, String? reaction) async {
    final box = HiveCacheManager.instance.storyReactionsBox;
    if (reaction == null) {
      await box.delete(storyId);
    } else {
      await box.put(storyId, reaction);
    }
  }
}
