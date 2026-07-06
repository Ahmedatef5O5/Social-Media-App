abstract class SupabaseConstants {
  // ── Shared / Auth ──
  static const String users = 'users';

  // ── Posts Feature ──
  static const String stories = 'stories';
  static const String storyVideos = 'story_videos';
  static const String posts = 'posts';
  static const String likes = 'post_likes';
  static const String comments = 'comments';

  // ── Chat Feature ──
  static const String messages = 'messages';
  static const String messageReactions = 'message_reactions';
  static const String typingStatus = 'typing_status';

  //  Group Chat Feature
  static const String groups = 'groups';
  static const String groupMembers = 'group_members';
  static const String groupMessages = 'group_messages';
  static const String groupMessageReactions = 'group_message_reactions';
  static const String groupTypingStatus = 'group_typing_status';

  //  Presence Feature
  static const String userPresence = 'user_presence';

  // ── RPC (Stored Functions) ──
  static const String getChatsWithLastMessage = 'get_chats_with_last_message';
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
  static const String shares = 'shares';

  static const String imagePublicId = 'image_public_id';
  static const String videoPublicId = 'video_public_id';
  static const String filePublicId = 'file_public_id';
}

// subClass for likes column table
abstract class LikeColumns {
  static const String id = 'id';
  static const String postId = 'post_id';
  static const String userId = 'user_id';
  static const String reaction = 'reaction';
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
}

// subClass for Messages column table
abstract class MessagesColumns {
  static const String id = 'id';
  static const String messageText = 'message_text';
  static const String senderId = 'sender_id';
  static const String receiverId = 'receiver_id';
  static const String createdAt = 'created_at';
  static const String isRead = 'is_read';
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
