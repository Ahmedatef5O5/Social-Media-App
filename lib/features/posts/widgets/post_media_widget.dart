import 'package:flutter/material.dart';
import 'package:social_media_app/core/widgets/cached_cloudinary_image.dart';
import 'package:social_media_app/features/posts/widgets/post_video_player.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/blurred_media_placeholders.dart';
import '../cubits/posts_cubit/posts_cubit.dart';
import '../models/post_model.dart';
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
            child: AspectRatio(
              aspectRatio: post.mediaAspectRatio,

              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CachedCloudinaryImage(
                  secureUrl: post.imageUrl!,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  placeholder:
                      (context) =>
                          BlurredImagePlaceholder(secureUrl: post.imageUrl!),
                  errorWidget:
                      (context, error) => SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.3,
                        child: const Icon(Icons.error),
                      ),
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
            aspectRatio: post.mediaAspectRatio,
          ),
        if (post.fileUrl != null && post.fileUrl!.isNotEmpty)
          FileAttachmentPreview(url: post.fileUrl!),
      ],
    );
  }
}
