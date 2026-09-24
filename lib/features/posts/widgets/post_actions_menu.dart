import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import 'package:social_media_app/features/posts/models/post_model.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/toast/app_toast.dart';
import '../../../core/widgets/custom_confirmation_dialog.dart';
import '../cubits/posts_cubit/posts_cubit.dart';

class PostActionsMenu extends StatelessWidget {
  final PostModel post;
  final String currentUserId;
  final PostsCubit postsCubit;
  final bool showPinAction;

  const PostActionsMenu({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.postsCubit,
    this.showPinAction = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isShareWrapper = post.isSharedPost;
    final bool isMine = post.authorId == currentUserId;
    final neutral = AppColors.grey8.withValues(alpha: 0.9);

    return PopupMenuButton<String?>(
      icon: Icon(Icons.more_vert),
      color: AppColors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) => _handleMenuSelection(context, value!),
      itemBuilder:
          (context) => [
            if (isMine) ...[
              // Above "Delete", profile view + owner only.
              if (showPinAction)
                PopupMenuItem(
                  value: 'pin',
                  child: Row(
                    children: [
                      if (post.isPinned)
                        FaIcon(
                          FontAwesomeIcons.thumbtackSlash,
                          size: 16,
                          color: neutral,
                        )
                      else
                        Icon(Icons.push_pin_outlined, color: neutral),
                      const Gap(8),
                      Text(
                        post.isPinned ? 'Unpin Post' : 'Pin Post',
                        style: Theme.of(
                          context,
                        ).textTheme.titleSmall!.copyWith(color: neutral),
                      ),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      isShareWrapper
                          ? Icons.repeat_rounded
                          : Icons.delete_outline,
                      color: Colors.red,
                    ),
                    Gap(8),
                    Text(
                      isShareWrapper ? 'Remove Share' : 'Delete',
                      style: Theme.of(
                        context,
                      ).textTheme.titleSmall!.copyWith(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ] else
              PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.report_gmailerrorred, color: neutral),
                    Gap(8),
                    Text(
                      'Report Post',
                      style: Theme.of(
                        context,
                      ).textTheme.titleSmall!.copyWith(color: neutral),
                    ),
                  ],
                ),
              ),
          ],
    );
  }

  Future<void> _handleMenuSelection(BuildContext context, String value) async {
    final bool isShareWrapper = post.isSharedPost;

    if (value == 'pin') {
      // Optimistic: the UI already changed when this returns; on failure the
      // cubit rolled back and told the user why.
      final result = await postsCubit.togglePin(post.id);
      if (!context.mounted) return;
      if (result == PinResult.pinned) {
        AppToast.info('Post pinned to your profile');
      } else if (result == PinResult.unpinned) {
        AppToast.info('Post unpinned');
      }
    } else if (value == 'delete') {
      showDialog(
        context: context,
        builder:
            (ctx) => CustomConfirmationDialog(
              title:
                  isShareWrapper
                      ? 'Remove this share from your profile?'
                      : 'Are you sure you want to delete this post?',
              img: AppImages.deleteFilesAnimationLot,
              onConfirm: () async {
                Navigator.pop(ctx);
                if (isShareWrapper) {
                  await postsCubit.toggleSharePost(post);
                } else {
                  await postsCubit.deletePost(post.id);
                }
                if (context.mounted) {
                  AppToast.info(
                    isShareWrapper
                        ? 'Share removed'
                        : 'Post deleted successfully',
                  );
                }
              },
            ),
      );
    } else if (value == 'report') {
      if (context.mounted) {
        AppToast.info('Post Reported successfully');
      }
    }
  }
}
