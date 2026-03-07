abstract class AppTablesNames {
  static const String users = 'users';
  static const String stories = 'stories';
  static const String posts = 'posts';
}

// subClass for users column table
abstract class UserColumns {
  static const String id = 'id';
  static const String name = 'name';
  static const String email = 'email';
  static const String imageUrl = 'image_url';
  static const String title = 'title';
}

// subClass for stories column table
abstract class StoryColumns {
  static const String id = 'id';
  static const String createdAt = 'created_at';
  static const String imageUrl = 'image_url';
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
