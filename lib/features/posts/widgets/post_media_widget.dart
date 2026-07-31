import 'package:flutter/material.dart';
import 'package:social_media_app/core/widgets/cached_cloudinary_image.dart';
import 'package:social_media_app/features/posts/widgets/post_video_player.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../cubit/posts_cubit/posts_cubit.dart';
import '../model/post_model.dart';
import 'file_attachment_preview.dart';

class PostMediaWidget extends StatelessWidget {
  final PostModel post;
  final PostsCubit postsCubit;
  final String currentUserId;

  const PostMediaWidget({
    super.key,
    required this.post,
    required this.postsCubit,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
          GestureDetector(
            onTap:
                () => Navigator.of(context, rootNavigator: true).pushNamed(
                  AppRoutes.fullScreenImageViewRoute,
                  arguments: {'url': post.imageUrl},
                ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: CachedCloudinaryImage(
                secureUrl: post.imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder:
                    (context) => Container(
                      height: MediaQuery.sizeOf(context).height * 0.3,
                      decoration: BoxDecoration(
                        color: AppColors.grey4.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const CustomLoadingIndicator(),
                    ),
                errorWidget:
                    (context, error) => SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.3,
                      child: const Icon(Icons.error),
                    ),
              ),
            ),
          ),
        if (post.videoUrl != null && post.videoUrl!.isNotEmpty)
          PostVideoPlayer(
            videoUrl: post.videoUrl!,
            post: post,
            postsCubit: postsCubit,
            currentUserId: currentUserId,
          ),
        if (post.fileUrl != null && post.fileUrl!.isNotEmpty)
          FileAttachmentPreview(url: post.fileUrl!),
      ],
    );
  }
}
