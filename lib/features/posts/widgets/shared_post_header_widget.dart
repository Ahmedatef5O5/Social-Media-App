import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import '../../../core/helpers/formatted_date.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../home/cubits/home_cubit/home_cubit.dart';
import '../cubit/posts_cubit/posts_cubit.dart';
import '../model/post_model.dart';
import 'post_actions_menu.dart';

class SharedPostHeaderWidget extends StatelessWidget {
  final PostModel sharedPost;
  final String currentUserId;
  final PostsCubit postsCubit;

  const SharedPostHeaderWidget({
    super.key,
    required this.sharedPost,
    required this.currentUserId,
    required this.postsCubit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final navController = context.read<HomeCubit>().navController;
    final currentRoute = ModalRoute.of(context);
    final currentArgs = currentRoute?.settings.arguments;

    final bool isPostByMe = sharedPost.authorId == currentUserId;
    final bool isAlreadyOnSameProfile =
        currentRoute?.settings.name == AppRoutes.profileViewRoute &&
        (currentArgs == sharedPost.authorId ||
            (currentArgs == null && isPostByMe));
    final bool shouldDisableTap = isAlreadyOnSameProfile;

    void openSharerProfile() {
      if (isPostByMe) {
        navController?.jumpToTab(3);
      } else {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushNamed(AppRoutes.profileViewRoute, arguments: sharedPost.authorId);
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: shouldDisableTap ? null : openSharerProfile,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.15),
                    width: 1.5,
                  ),
                ),
                child: AppAvatar(imageUrl: sharedPost.authorImageUrl, size: 38),
              ),
              Positioned(
                right: -3,
                bottom: -1,
                child: Container(
                  padding: const EdgeInsets.all(3.5),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.repeat_rounded,
                    size: 11,
                    color: theme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Gap(10),
        Expanded(
          child: GestureDetector(
            onTap: shouldDisableTap ? null : openSharerProfile,
            behavior: HitTestBehavior.opaque,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    children: [
                      TextSpan(
                        text: sharedPost.authorName ?? 'Unknown',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                          fontSize: 13.5,
                        ),
                      ),
                      const TextSpan(
                        text: '  shared a post',
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      FormattedDate.getFormattedDate(
                        DateTime.parse(
                          sharedPost.createdAt,
                        ).toLocal().toIso8601String(),
                      ),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 9.5,
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        PostActionsMenu(
          post: sharedPost,
          currentUserId: currentUserId,
          postsCubit: postsCubit,
        ),
      ],
    );
  }
}
