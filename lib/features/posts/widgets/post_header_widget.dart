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
import '../../group_chats/helpers/group_profile_navigation.dart';
import '../../group_chats/helpers/group_role_resolver.dart';
import 'author_image_widget.dart';
import 'group_post_header_leading.dart';
import 'pinned_post_badge.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

class PostHeaderWidget extends StatelessWidget {
  final PostModel post;
  final String currentUserId;
  final PostsCubit postsCubit;
  final bool showPinAction;
  final bool showPinnedBadge;
  final bool isProfileContext;
  final HeaderTrailingAction trailingAction;

  const PostHeaderWidget({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.postsCubit,
    this.showPinAction = false,
    this.showPinnedBadge = false,
    this.isProfileContext = false,
    this.trailingAction = HeaderTrailingAction.moreActions,
  });

  Widget _buildOpenOriginalButton(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.open_in_new_rounded,
        color: Theme.of(context).primaryColor.withValues(alpha: 0.75),
        size: 19,
      ),
      tooltip: context.l10n.openOriginalPost,
      onPressed: () {
        if (postsCubit.isPostGhost(post.id)) {
          AppToast.info(context.l10n.thisPostIsNo);
          return;
        }
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushNamed(AppRoutes.postDetailsViewRoute, arguments: post);
      },
    );
  }

  Widget _buildSuggestedBadge(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsetsDirectional.only(start: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        context.l10n.suggestedForYou,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 9.3,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  void _openAuthor(
    BuildContext context, {
    required bool isPostByMe,
    required dynamic navController,
  }) {
    if (isPostByMe) {
      if (navController != null) navController.jumpToTab(3);
    } else {
      Navigator.of(
        context,
        rootNavigator: true,
      ).pushNamed(AppRoutes.profileViewRoute, arguments: post.authorId);
    }
  }

  /// Group post header: layered group + author avatar, group name as the
  /// title, and "Author • time • privacy" as the subtitle.
  Widget _buildGroupHeader(
    BuildContext context, {
    required bool isPostByMe,
    required dynamic navController,
    required bool shouldDisableTap,
    required bool isAlreadyOnSamePost,
    required Widget? trailing,
  }) {
    final theme = Theme.of(context);
    final groupId = post.groupId ?? '';
    final onGroup = isOnGroupProfile(context, groupId);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.45);
    final authorName =
        (post.authorIsDeleted ||
                (post.authorName?.trim().toLowerCase() == 'deleted account'))
            ? context.l10n.deletedAccount
            : (post.authorName ?? context.l10n.unknown);

    void openGroup() {
      if (onGroup || groupId.isEmpty) return;
      openGroupProfile(context, groupId: groupId);
    }

    void openAuthor() {
      if (shouldDisableTap) return;
      _openAuthor(
        context,
        isPostByMe: isPostByMe,
        navController: navController,
      );
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: GroupPostHeaderLeading(
        groupAvatarUrl: post.groupAvatarUrl,
        authorImageUrl: post.authorImageUrl,
        onGroupTap: onGroup ? null : openGroup,
        onAuthorTap: shouldDisableTap ? null : openAuthor,
      ),
      onTap:
          isAlreadyOnSamePost
              ? null
              : () {
                if (postsCubit.isPostGhost(post.id)) {
                  AppToast.info(context.l10n.thisPostIsNo);
                  return;
                }
                Navigator.of(context, rootNavigator: true).pushNamed(
                  AppRoutes.postDetailsViewRoute,
                  arguments: PostDetailsRouteArgs(
                    post: post,
                    initialActiveMode: PostDetailsActiveMode.comments,
                    isProfileContext: isProfileContext,
                  ),
                );
              },
      title: GestureDetector(
        onTap: onGroup ? null : openGroup,
        child: Text(
          post.groupName?.trim().isNotEmpty == true
              ? post.groupName!
              : context.l10n.group,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall!.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: context.ls(0),
          ),
        ),
      ),
      subtitle: Row(
        children: [
          Flexible(
            child: GestureDetector(
              onTap: shouldDisableTap ? null : openAuthor,
              child: Text(
                authorName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall!.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 11.5,
                  color: muted,
                  letterSpacing: context.ls(0),
                ),
              ),
            ),
          ),
          Text(
            ' • ${FormattedDate.getFormattedDate(DateTime.parse(post.createdAt).toLocal().toIso8601String())} • ',
            style: theme.textTheme.titleSmall!.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 10.5,
              color: muted,
              letterSpacing: context.ls(0),
            ),
          ),
          // Groups are members-only => lock icon as the privacy marker.
          Icon(Icons.lock_outline, size: 11, color: muted),
          if (showPinnedBadge) ...[
            const SizedBox(width: 6),
            const PinnedPostBadge(),
          ],
        ],
      ),
      trailing: trailing,
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

    // Ghost accounts have nothing to open (no preview dialog, no profile).
    bool shouldDisableTap = isAlreadyOnSameProfile || post.authorIsDeleted;

    Widget? buildTrailingWidget() {
      final colorScheme = Theme.of(context).colorScheme;

      switch (trailingAction) {
        case HeaderTrailingAction.moreActions:
          if (post.isGroupPost && !isPostByMe) {
            // Owner / admins may remove any post of their group.
            return FutureBuilder<bool>(
              future: GroupRoleResolver.isAdmin(post.groupId!),
              builder:
                  (context, snap) => PostActionsMenu(
                    post: post,
                    currentUserId: currentUserId,
                    postsCubit: postsCubit,
                    showPinAction: showPinAction,
                    canModerateGroupPost: snap.data == true,
                  ),
            );
          }
          return PostActionsMenu(
            post: post,
            currentUserId: currentUserId,
            postsCubit: postsCubit,
            showPinAction: showPinAction,
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
                showPinAction: showPinAction,
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
            tooltip: context.l10n.close,
            onPressed: () => Navigator.of(context).pop(),
          );

        case HeaderTrailingAction.none:
          return const SizedBox.shrink();
      }
    }

    if (post.isGroupPost) {
      return _buildGroupHeader(
        context,
        isPostByMe: isPostByMe,
        navController: navController,
        shouldDisableTap: shouldDisableTap,
        isAlreadyOnSamePost: isAlreadyOnSamePost,
        trailing: buildTrailingWidget(),
      );
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
                  AppToast.info(context.l10n.thisPostIsNo);
                  return;
                }
                Navigator.of(context, rootNavigator: true).pushNamed(
                  AppRoutes.postDetailsViewRoute,
                  arguments: PostDetailsRouteArgs(
                    post: post,
                    initialActiveMode: PostDetailsActiveMode.comments,
                    isProfileContext: isProfileContext,
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                (post.authorIsDeleted ||
                        (post.authorName?.trim().toLowerCase() ==
                            'deleted account'))
                    ? context.l10n.deletedAccount
                    : (post.authorName ?? context.l10n.unknown),
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
            if (post.isSuggestedForYou) _buildSuggestedBadge(context),
          ],
        ),
      ),
      subtitle: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: Row(
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
            if (showPinnedBadge) ...[
              const SizedBox(width: 6),
              const PinnedPostBadge(),
            ],
          ],
        ),
      ),
      trailing: buildTrailingWidget(),
    );
  }
}
