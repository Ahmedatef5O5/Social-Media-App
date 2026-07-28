import 'package:flutter/material.dart';
import '../../features/single_chats/models/message_model.dart';
import '../router/app_routes.dart';
import '../toast/app_toast.dart';

class StoryReplyNavigator {
  static void openOriginalStory(BuildContext context, MessageModel message) {
    final storyId = message.replyToStoryId;
    if (storyId == null) {
      AppToast.warning('This story is no longer available');
      return;
    }

    Navigator.of(context, rootNavigator: true).pushNamed(
      AppRoutes.storyDisplayViewRoute,
      arguments: {'storyId': storyId, 'authorId': message.replyToStoryAuthorId},
    );
  }
}
