import 'package:supabase_flutter/supabase_flutter.dart';

sealed class FeedEvent {
  const FeedEvent();
}

final class PostInsertedEvent extends FeedEvent {
  final String postId;
  const PostInsertedEvent(this.postId);
}

final class PostUpdatedEvent extends FeedEvent {
  final String postId;
  const PostUpdatedEvent(this.postId);
}

final class PostDeletedEvent extends FeedEvent {
  final String postId;
  const PostDeletedEvent(this.postId);
}

final class LikeChangedEvent extends FeedEvent {
  final String postId;
  final PostgresChangeEvent changeType;
  const LikeChangedEvent(this.postId, this.changeType);
}

final class ShareChangedEvent extends FeedEvent {
  final String postId;
  final PostgresChangeEvent changeType;
  const ShareChangedEvent(this.postId, this.changeType);
}

// TODO:
// final class SavedChangedEvent extends FeedEvent {
//   final String postId;
//   final PostgresChangeEvent changeType;
//   const SavedChangedEvent(this.postId, this.changeType);
// }

final class PresenceChangedEvent extends FeedEvent {
  final String userId;
  final bool isOnline;
  final DateTime? updatedAt;
  const PresenceChangedEvent(this.userId, this.isOnline, this.updatedAt);
}
