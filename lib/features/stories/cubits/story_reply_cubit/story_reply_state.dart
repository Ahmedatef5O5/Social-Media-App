part of 'story_reply_cubit.dart';

sealed class StoryReplyState {
  const StoryReplyState();
}

final class StoryReplyIdle extends StoryReplyState {}

final class StoryReplySending extends StoryReplyState {}

final class StoryReplySent extends StoryReplyState {}

final class StoryReplyFailed extends StoryReplyState {
  final String message;
  const StoryReplyFailed(this.message);
}
