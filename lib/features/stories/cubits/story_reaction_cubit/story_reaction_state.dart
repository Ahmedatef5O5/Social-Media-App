part of 'story_reaction_cubit.dart';

sealed class StoryReactionState {
  const StoryReactionState();
  String? get myReaction;
}

final class StoryReactionIdle extends StoryReactionState {
  @override
  final String? myReaction;
  const StoryReactionIdle(this.myReaction);
}

final class StoryReactionSaving extends StoryReactionState {
  @override
  final String? myReaction;
  const StoryReactionSaving(this.myReaction);
}

final class StoryReactionFailed extends StoryReactionState {
  @override
  final String? myReaction;
  final String message;
  const StoryReactionFailed(this.myReaction, this.message);
}
