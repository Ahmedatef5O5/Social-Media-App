import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/features/posts/widgets/post_actions_menu.dart';
import '../../../core/helpers/formatted_date.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/toast/app_toast.dart';
import '../../profile/widgets/user_preview_dialog.dart';
import '../../home/cubits/home_cubit/home_cubit.dart';
import '../../social_graph/models/content_privacy.dart';
import '../cubits/posts_cubit/posts_cubit.dart';
import '../helpers/header_trailing_action.dart';
import '../models/post_details_route_args.dart';
import '../models/post_model.dart';
import '../views/post_details_view.dart';
import 'author_image_widget.dart';

class PostHeaderWidget extends StatelessWidget {
  final PostModel post;
  final String currentUserId;
  final PostsCubit postsCubit;
  final HeaderTrailingAction trailingAction;

  const PostHeaderWidget({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.postsCubit,
    this.trailingAction = HeaderTrailingAction.moreActions,
  });

  Widget _buildOpenOriginalButton(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.open_in_new_rounded,
        color: Theme.of(context).primaryColor.withValues(alpha: 0.75),
        size: 19,
      ),
      tooltip: 'Open original post',
      onPressed: () {
        if (postsCubit.isPostGhost(post.id)) {
          AppToast.info('This post is no longer available.');
          return;
        }
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushNamed(AppRoutes.postDetailsViewRoute, arguments: post);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = SupabaseProvider.id;
    final navController = context.read<HomeCubit>().navController;

    final currentRoute = ModalRoute.of(context);
    final currentArgs = currentRoute?.settings.arguments;

    bool isPostByMe = post.authorId == currentUserId;

    bool isAlreadyOnSameProfile =
        currentRoute?.settings.name == AppRoutes.profileViewRoute &&
        (currentArgs == post.authorId || (currentArgs == null && isPostByMe));

    bool isAlreadyOnSamePost = false;
    if (currentRoute?.settings.name == AppRoutes.postDetailsViewRoute) {
      if (currentArgs is PostModel && currentArgs.id == post.id) {
        isAlreadyOnSamePost = true;
      } else if (currentArgs is PostDetailsRouteArgs &&
          currentArgs.post.id == post.id) {
        isAlreadyOnSamePost = true;
      }
    }

    bool shouldDisableTap = isAlreadyOnSameProfile;

    Widget? buildTrailingWidget() {
      final colorScheme = Theme.of(context).colorScheme;

      switch (trailingAction) {
        case HeaderTrailingAction.moreActions:
          return PostActionsMenu(
            post: post,
            currentUserId: currentUserId,
            postsCubit: postsCubit,
          );

        case HeaderTrailingAction.openOriginal:
          return _buildOpenOriginalButton(context);

        case HeaderTrailingAction.moreActionsAndOpenOriginal:
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildOpenOriginalButton(context),
              PostActionsMenu(
                post: post,
                currentUserId: currentUserId,
                postsCubit: postsCubit,
              ),
            ],
          );

        case HeaderTrailingAction.closeScreen:
          return IconButton(
            icon: Icon(
              Icons.close_rounded,
              color: colorScheme.onSurface.withValues(alpha: 0.8),
              size: 26,
            ),
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          );

        case HeaderTrailingAction.none:
          return const SizedBox.shrink();
      }
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: AuthorImageWidget(
        post: post,
        onTap:
            shouldDisableTap
                ? null
                : () {
                  if (isPostByMe) {
                    if (navController != null) {
                      navController.jumpToTab(3);
                    }
                  } else {
                    showDialog(
                      context: context,
                      builder:
                          (context) => UserPreviewDialog(
                            user: post.toChatUserModel(),
                            showContactOptions: false,
                          ),
                    );
                  }
                },
      ),

      onTap:
          isAlreadyOnSamePost
              ? null
              : () {
                if (postsCubit.isPostGhost(post.id)) {
                  AppToast.info('This post is no longer available.');
                  return;
                }
                Navigator.of(context, rootNavigator: true).pushNamed(
                  AppRoutes.postDetailsViewRoute,
                  arguments: PostDetailsRouteArgs(
                    post: post,
                    initialActiveMode: PostDetailsActiveMode.comments,
                  ),
                );
              },

      title: GestureDetector(
        onTap:
            shouldDisableTap
                ? null
                : () {
                  if (isPostByMe) {
                    if (navController != null) {
                      navController.jumpToTab(3);
                    }
                  } else {
                    Navigator.of(context, rootNavigator: true).pushNamed(
                      AppRoutes.profileViewRoute,
                      arguments: post.authorId,
                    );
                  }
                },
        child: Text(
          post.authorName ?? 'Unknown',
          style: Theme.of(context).textTheme.titleSmall!.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
      ),
      subtitle: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            post.privacyType.icon,
            size: 11,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.4),
          ),

          const SizedBox(width: 2.8),
          Text(
            FormattedDate.getFormattedDate(
              DateTime.parse(post.createdAt).toLocal().toIso8601String(),
            ),
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 10.3,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
      trailing: buildTrailingWidget(),
    );
  }
}
