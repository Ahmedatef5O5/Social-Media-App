import 'package:flutter/material.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import '../../features/stories/cubit/stories_cubit/stories_cubit.dart';
import '../router/app_routes.dart';
import '../../features/stories/model/story_model.dart';
import '../../features/single_chats/models/message_model.dart';
import '../toast/app_toast.dart';

class StoryReplyNavigator {
  static Future<void> openOriginalStory(
    BuildContext context,
    MessageModel message,
  ) async {
    if (message.replyToStoryId == null) {
      AppToast.warning('This story is no longer available');
      return;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black26,
      barrierDismissible: false,
      builder:
          (_) => Center(
            child: SizedBox(
              height: 95,
              width: 95,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const CustomLoadingIndicator(),
              ),
            ),
          ),
    );

    final storiesCubit = StoriesCubit();
    try {
      await storiesCubit.fetchStories();
      final stories = storiesCubit.cachedStories;

      final Map<String, List<StoryModel>> storiesByUser = {};
      for (final story in stories) {
        storiesByUser.putIfAbsent(story.authorId, () => []).add(story);
      }
      final groups = storiesByUser.values.toList();

      final groupIndex = groups.indexWhere(
        (g) => g.any((s) => s.id == message.replyToStoryId),
      );

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      if (groupIndex == -1) {
        AppToast.warning('This story is no longer available');
        await storiesCubit.close();
        return;
      }

      final storyIndex = groups[groupIndex].indexWhere(
        (s) => s.id == message.replyToStoryId,
      );

      await Navigator.of(context, rootNavigator: true).pushNamed(
        AppRoutes.storyDisplayViewRoute,
        arguments: {
          'storiesCubit': storiesCubit,
          'allUserGroups': groups,
          'initialGroupIndex': groupIndex,
          'initialStoryIndex': storyIndex < 0 ? 0 : storyIndex,
        },
      );
      await storiesCubit.close();
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        AppToast.error('Failed to open story: $e');
      }
      await storiesCubit.close();
    }
  }
}
