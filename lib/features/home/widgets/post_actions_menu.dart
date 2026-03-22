import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import 'package:social_media_app/features/home/models/post_model.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/widgets/custom_confirmation_dialog.dart';
import '../cubit/home_cubit.dart';

class PostActionsMenu extends StatelessWidget {
  final PostModel post;
  final String currentUserId;
  final HomeCubit homeCubit;
  const PostActionsMenu({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.homeCubit,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String?>(
      icon: Icon(Icons.more_vert),
      color: AppColors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) => _handleMenuSelection(context, value!),

      itemBuilder:
          (context) => [
            if (post.authorId == currentUserId)
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red),
                    Gap(8),
                    Text('Delete'),
                  ],
                ),
              )
            else
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.report_gmailerrorred),
                    Gap(8),
                    Text('Report Post'),
                  ],
                ),
              ),
          ],
    );
  }

  void _handleMenuSelection(BuildContext context, String value) {
    if (value == 'delete') {
      showDialog(
        context: context,
        builder:
            (ctx) => CustomConfirmationDialog(
              title: 'Are you sure you want to delete this post?',
              img: AppImages.deleteFilesAnimationLot,
              onConfirm: () async {
                Navigator.pop(ctx);
                await homeCubit.deletePost(post.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Post deleted successfully'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
      );
    } else if (value == 'report') {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post Reported successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
