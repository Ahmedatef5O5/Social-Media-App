abstract class SupabaseConstants {
  static const String users = 'users';
  static const String stories = 'stories';
  static const String posts = 'posts';
  static const String likes = 'post_likes';
  static const String comments = 'comments';
  static const String messages = 'messages';
  static const String typingStatus = 'typing_status';

  //  RPC (Functions)
  static const String getChatsWithLastMessage = 'get_chats_with_last_message';
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
}

// subClass for stories column table
abstract class StoryColumns {
  static const String id = 'id';
  static const String createdAt = 'created_at';
  static const String imageUrl = 'image_url';
  static const String contentText = 'content_text';
  static const String backgroundColor = 'background_color';
  static const String authorId = 'author_id';
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
}

// subClass for likes column table
abstract class LikeColumns {
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
  static const String likes = 'likes';
  static const String replays = 'replays';
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
  static const String reaction = 'reaction';

  static const String replyToMessageId = 'reply_to_message_id';
  static const String replyToText = 'reply_to_text';
  static const String replyToMessageType = 'reply_to_message_type';
  static const String replyToSenderId = 'reply_to_sender_id';
}

// subClass for users Status column table
abstract class TypingStatusColumns {
  static const String chatId = 'chat_id';
  static const String userId = 'user_id';
  static const String isTyping = 'is_typing';
  static const String updatedAt = 'updated_at';
}
