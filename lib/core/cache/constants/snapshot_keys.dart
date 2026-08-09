class SnapshotKeys {
  const SnapshotKeys._();

  static const String posts = 'posts_snapshot';
  static const String stories = 'stories_snapshot';
  static const String chats = 'chats_snapshot';
  static const String currentUser = 'current_user_snapshot';
  static const String groups = 'groups_snapshot';
  static const String conversationFlags = 'conversation_flags_snapshot';
  static const String clearedSingleChats = 'cleared_chats_snapshot';
  static const String clearedGroupChats = 'cleared_group_chats_snapshot';
  static String storyViews(String storyId) => 'story_views_snapshot_$storyId';
}
