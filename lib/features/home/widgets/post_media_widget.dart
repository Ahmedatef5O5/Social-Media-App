import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/features/home/widgets/post_video_player.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../models/post_model.dart';
import 'file_attachment_preview.dart';

class PostMediaWidget extends StatelessWidget {
  const PostMediaWidget({super.key, required this.post});

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
          GestureDetector(
            onTap:
                () => Navigator.of(context, rootNavigator: true).pushNamed(
                  AppRoutes.fullScreenImageViewRoute,
                  arguments: {
                    'url': post.imageUrl,
                    'tag': '${post.id}_${post.imageUrl}',
                  },
                ),
            child: Hero(
              tag: '${post.id}_${post.imageUrl}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child:
                    post.imageUrl != null
                        ? CachedNetworkImage(
                          imageUrl: post.imageUrl!,
                          width: double.infinity,

                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => Container(
                                height: MediaQuery.sizeOf(context).height * 0.3,
                                decoration: BoxDecoration(
                                  color: AppColors.grey7.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: const CustomLoadingIndicator(),
                              ),
                          errorWidget:
                              (context, url, error) => const Icon(Icons.error),
                          filterQuality: FilterQuality.high,

                          memCacheWidth: 800,
                        )
                        : null,
              ),
            ),
          ),
        if (post.videoUrl != null && post.videoUrl!.isNotEmpty)
          PostVideoPlayer(videoUrl: post.videoUrl!),
        if (post.fileUrl != null && post.fileUrl!.isNotEmpty)
          FileAttachmentPreview(url: post.fileUrl!, onTap: () {}),
      ],
    );
  }
}
