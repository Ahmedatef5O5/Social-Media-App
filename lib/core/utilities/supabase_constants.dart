abstract class SupabaseConstants {
  // ── Shared / Auth ──
  static const String users = 'users';

  // social Graphy
  static const String friendships = 'friendships';
  static const String follows = 'follows';
  static const String getDiscoverPeopleRpc = 'get_discover_people';
  static const String postAllowedViewers = 'post_allowed_viewers';
  static const String storyAllowedViewers = 'story_allowed_viewers';

  // ── Posts Feature ──
  static const String stories = 'stories';
  static const String storyVideos = 'story_videos';
  static const String posts = 'posts';
  static const String likes = 'post_likes';
  static const String comments = 'comments';
  static const String savedPosts = 'saved_posts';
  static const String postShares = 'post_shares';

  // ── Chat Feature ──
  static const String messages = 'messages';
  static const String messageRequests = 'message_requests';
  static const String messageReactions = 'message_reactions';
  static const String typingStatus = 'typing_status';

  //  Group Chat Feature
  static const String groups = 'groups';
  static const String groupMembers = 'group_members';
  static const String groupMessages = 'group_messages';
  static const String groupMessageReactions = 'group_message_reactions';
  static const String groupMessageMentions = 'group_message_mentions';
  static const String groupTypingStatus = 'group_typing_status';

  //  Presence Feature
  static const String userPresence = 'user_presence';

  // ── Stories Reactions & Views Feature ──
  static const String storyViews = 'story_views';
  static const String storyReactions = 'story_reactions';

  // ── Stickers Feature ──
  static const String stickerPacks = 'sticker_packs';
  static const String stickers = 'stickers';

  // ── RPC (Stored Functions) ──
  static const String getChatsWithLastMessage = 'get_chats_with_last_message';
  static const String toggleStoryReactionRpc = 'toggle_story_reaction';
  static const String markStoryViewedRpc = 'mark_story_viewed';
  static const String getMyStoriesOverviewRpc = 'get_my_stories_overview';
  static const String getStoryViewersRpc = 'get_story_viewers';
  static const String togglePostShareRpc = 'toggle_post_share';
  // comments_upgrade_migration.sql
  static const String addCommentWithMentionsRpc = 'add_comment_with_mentions';

  static const String getProfileOverviewRpc = 'get_profile_overview';


  // ── Reels Feature ──
  static const String reelChannels = 'reel_channels';
  static const String reelsCache = 'reels_cache';
}

// Friendship Columns
abstract class FriendshipColumns {
  static const String id = 'id';
  static const String requesterId = 'requester_id';
  static const String addresseeId = 'addressee_id';
  static const String status = 'status';
  static const String createdAt = 'created_at';
  static const String respondedAt = 'responded_at';
}

abstract class FollowColumns {
  static const String followerId = 'follower_id';
  static const String followingId = 'following_id';
  static const String createdAt = 'created_at';
}

// groups
abstract class GroupColumns {
  static const String id = 'id';
  static const String name = 'name';
  static const String description = 'description';
  static const String avatarUrl = 'avatar_url';
  static const String createdAt = 'created_at';
  static const String createdBy = 'created_by';

  static const String avatarPublicId = 'avatar_public_id';
}

// group_members
abstract class GroupMemberColumns {
  static const String groupId = 'group_id';
  static const String userId = 'user_id';
  static const String role = 'role';
  static const String joinedAt = 'joined_at';
}

// group_messages
abstract class GroupMessageColumns {
  static const String id = 'id';
  static const String groupId = 'group_id';
  static const String senderId = 'sender_id';
  static const String text = 'text';
  static const String messageType = 'message_type';
  static const String imageUrl = 'image_url';
  static const String videoUrl = 'video_url';
  static const String voiceUrl = 'voice_url';
  static const String caption = 'caption';
  static const String createdAt = 'created_at';
  static const String replyToId = 'reply_to_id';
  static const String isEdited = 'is_edited';
  static const String updatedAt = 'updated_at';

  static const String imagePublicId = 'image_public_id';
  static const String videoPublicId = 'video_public_id';
  static const String voicePublicId = 'voice_public_id';
}

// group_message_reactions
abstract class GroupReactionColumns {
  static const String id = 'id';
  static const String messageId = 'message_id';
  static const String userId = 'user_id';
  static const String reaction = 'reaction';
  static const String groupId = 'group_id';
}

// group_message_mentions
abstract class GroupMessageMentionColumns {
  static const String id = 'id';
  static const String groupMessageId = 'group_message_id';
  static const String groupId = 'group_id';
  static const String mentionedUserId = 'mentioned_user_id';
  static const String startIndex = 'start_index';
  static const String endIndex = 'end_index';
  static const String createdAt = 'created_at';
}

// user_presence
abstract class PresenceColumns {
  static const String userId = 'user_id';
  static const String isOnline = 'is_online';
  static const String lastSeen = 'last_seen';
  static const String updatedAt = 'updated_at';
}

// group_typing_status
abstract class GroupTypingColumns {
  static const String groupId = 'group_id';
  static const String userId = 'user_id';
  static const String isTyping = 'is_typing';
  static const String updatedAt = 'updated_at';
}

// subClass for users column table
abstract class UserColumns {
  static const String id = 'id';
  static const String name = 'name';
  static const String email = 'email';
  static const String imageUrl = 'image_url';
  static const String title = 'title';
  static const String lastSeen = 'last_seen';
  static const String isTypingTo = 'is_typing_to';
  static const String theme = 'theme';
  static const String fcmToken = 'fcm_token';

  static const String imagePublicId = 'image_public_id';
  static const String backgroundImagePublicId = 'background_image_public_id';
}

// subClass for stories column table
abstract class StoryColumns {
  static const String id = 'id';
  static const String createdAt = 'created_at';
  static const String imageUrl = 'image_url';
  static const String videoUrl = 'video_url';
  static const String contentText = 'content_text';
  static const String backgroundColor = 'background_color';
  static const String authorId = 'author_id';
  static const String storyCaption = 'caption';

  static const String imagePublicId = 'image_public_id';
  static const String videoPublicId = 'video_public_id';

  static const String videoDurationSeconds = 'video_duration_seconds';

  static const String privacyType = 'privacy_type';
}

// subClass for story_views column table
abstract class StoryViewColumns {
  static const String id = 'id';
  static const String storyId = 'story_id';
  static const String viewerId = 'viewer_id';
  static const String viewedAt = 'viewed_at';
}

// subClass for story_reactions column table
abstract class StoryReactionColumns {
  static const String id = 'id';
  static const String storyId = 'story_id';
  static const String userId = 'user_id';
  static const String reaction = 'reaction';
  static const String createdAt = 'created_at';
}

// subClass for posts column table
abstract class PostColumns {
  static const String id = 'id';
  static const String text = 'text';
  static const String authorId = 'author_id';
  static const String createdAt = 'created_at';
  static const String imageUrl = 'image_url';
  static const String videoUrl = 'video_url';
  static const String likes = 'likes';
  static const String comments = 'comments';
  static const String imagePublicId = 'image_public_id';
  static const String videoPublicId = 'video_public_id';
  static const String filePublicId = 'file_public_id';
  // ── Shared Post feature ──
  static const String sharedPostId = 'shared_post_id';

  /// Alias used in the Supabase join query for the nested original post
  static const String originalPostRelation = 'original_post';

  // ── Shared Reel feature ──
  static const String sharedReelId = 'shared_reel_id';

  //
  static const String privacyType = 'privacy_type';
}

// subClass for post_shares column table
abstract class PostShareColumns {
  static const String id = 'id';
  static const String postId = 'post_id';
  static const String userId = 'user_id';
  static const String createdAt = 'created_at';
}

// subClass for likes column table
abstract class LikeColumns {
  static const String id = 'id';
  static const String postId = 'post_id';
  static const String userId = 'user_id';
  static const String reaction = 'reaction';
  static const String createdAt = 'created_at';
}

// subClass for sticker_packs column table
abstract class StickerPackColumns {
  static const String id = 'id';
  static const String title = 'title';
  static const String coverUrl = 'cover_url';
  static const String stickerCount = 'sticker_count';
  static const String sortOrder = 'sort_order';
  static const String createdAt = 'created_at';

  // Animated StickerPack
  static const String hasAnimated = 'has_animated';
}

// subClass for stickers column table
abstract class StickerColumns {
  static const String id = 'id';
  static const String packId = 'pack_id';
  static const String imageUrl = 'image_url';
  static const String sortOrder = 'sort_order';
  static const String createdAt = 'created_at';

  // ── Animation metadata (added for animated sticker support) ──
  static const String isAnimated = 'is_animated';
  static const String format = 'format';
}

// subClass for saved_posts column table
abstract class SavedPostColumns {
  static const String id = 'id';
  static const String postId = 'post_id';
  static const String userId = 'user_id';
  static const String createdAt = 'created_at';
}

// subClass for comments column table
abstract class CommentColumns {
  static const String id = 'id';
  static const String text = 'text';
  static const String postId = 'post_id';
  static const String authorId = 'author_id';
  static const String createdAt = 'created_at';
  static const String imageUrl = 'image_url';
  static const String videoUrl = 'video_url';
  static const String parentCommentId = 'parent_comment_id';
  static const String isEdited = 'is_edited';
  static const String updatedAt = 'updated_at';
  // ── Rich media (Comments upgrade) ──
  static const String commentType = 'comment_type';
  static const String voiceUrl = 'voice_url';
  static const String fileUrl = 'file_url';
  static const String fileName = 'file_name';
  static const String fileSizeBytes = 'file_size_bytes';
  static const String durationSeconds = 'duration_seconds';

  static const String imagePublicId = 'image_public_id';
  static const String videoPublicId = 'video_public_id';
  static const String voicePublicId = 'voice_public_id';
  static const String filePublicId = 'file_public_id';

  // ── Engagement counters, kept in sync by DB triggers ──
  static const String replyCount = 'reply_count';
  static const String reactionCount = 'reaction_count';
  static const String relevanceScore = 'relevance_score';
}

// subClass for comment_mentions column table
abstract class CommentMentionColumns {
  static const String id = 'id';
  static const String commentId = 'comment_id';
  static const String mentionedUserId = 'mentioned_user_id';
  static const String startIndex = 'start_index';
  static const String endIndex = 'end_index';
  static const String createdAt = 'created_at';
}

// subClass for Messages column table
abstract class MessagesColumns {
  static const String id = 'id';
  static const String messageText = 'message_text';
  static const String senderId = 'sender_id';
  static const String receiverId = 'receiver_id';
  static const String createdAt = 'created_at';
  static const String isRead = 'is_read';
  static const String isEdited = 'is_edited';
  static const String updatedAt = 'updated_at';
  static const String messageType = 'message_type';
  static const String imageUrl = 'image_url';
  static const String videoUrl = 'video_url';
  static const String voiceUrl = 'voice_url';
  static const String caption = 'caption';

  @Deprecated(
    'Use the message_reactions table + MessageReactionColumns instead',
  )
  static const String reaction = 'reaction';

  static const String replyToMessageId = 'reply_to_message_id';
  static const String replyToText = 'reply_to_text';
  static const String replyToMessageType = 'reply_to_message_type';
  static const String replyToSenderId = 'reply_to_sender_id';

  static const String deletedFor = 'deleted_for';

  // Migration for conversation_id column in messages table
  static const String conversationId = 'conversation_id';

  static const String imagePublicId = 'image_public_id';
  static const String videoPublicId = 'video_public_id';
  static const String voicePublicId = 'voice_public_id';

  static const String replyToStoryId = 'reply_to_story_id';
  static const String replyToStoryAuthorId = 'reply_to_story_author_id';
  static const String replyToStoryType = 'reply_to_story_type';
  static const String replyToStoryMediaUrl = 'reply_to_story_media_url';
  static const String replyToStoryText = 'reply_to_story_text';
  static const String replyToStoryBgColor = 'reply_to_story_bg_color';
  static const String replyToStoryDurationSeconds =
      'reply_to_story_duration_seconds';
}

// message_reactions
abstract class MessageReactionColumns {
  static const String id = 'id';
  static const String messageId = 'message_id';
  static const String userId = 'user_id';
  static const String reaction = 'reaction';
  static const String conversationId = 'conversation_id';
  static const String createdAt = 'created_at';
}

// subClass for users Status column table
abstract class TypingStatusColumns {
  static const String chatId = 'chat_id';
  static const String userId = 'user_id';
  static const String isTyping = 'is_typing';
  static const String updatedAt = 'updated_at';
}

// reel_channels
abstract class ReelChannelColumns {
  static const String id = 'id';
  static const String youtubeChannelId = 'youtube_channel_id';
  static const String channelName = 'channel_name';
  static const String channelAvatarUrl = 'channel_avatar_url';
  static const String isActive = 'is_active';
}

// reels_cache
abstract class ReelColumns {
  static const String id = 'id';
  static const String youtubeVideoId = 'youtube_video_id';
  static const String channelId = 'channel_id';
  static const String title = 'title';
  static const String description = 'description';
  static const String thumbnailUrl = 'thumbnail_url';
  static const String originalLikeCount = 'original_like_count';
  static const String originalViewCount = 'original_view_count';
  static const String publishedAt = 'published_at';
  static const String cachedAt = 'cached_at';
}