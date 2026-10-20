import 'package:flutter/material.dart';
import '../router/app_routes.dart';
import '../toast/app_toast.dart';
import 'package:social_media_app/core/localization/app_l10n.dart';

class StoryReplyNavigator {
  static void openOriginalStory(
    BuildContext context, {
    required String? storyId,
    required String? authorId,
  }) {
    if (storyId == null) {
      AppToast.warning(AppL10n.current.thisStoryIsNo);
      return;
    }

    Navigator.of(context, rootNavigator: true).pushNamed(
      AppRoutes.storyDisplayViewRoute,
      arguments: {'storyId': storyId, 'authorId': authorId},
    );
  }
}
