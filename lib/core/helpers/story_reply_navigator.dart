import 'package:flutter/material.dart';
import '../router/app_routes.dart';
import '../toast/app_toast.dart';

class StoryReplyNavigator {
  static void openOriginalStory(
    BuildContext context, {
    required String? storyId,
    required String? authorId,
  }) {
    if (storyId == null) {
      AppToast.warning('This story is no longer available');
      return;
    }

    Navigator.of(context, rootNavigator: true).pushNamed(
      AppRoutes.storyDisplayViewRoute,
      arguments: {'storyId': storyId, 'authorId': authorId},
    );
  }
}
