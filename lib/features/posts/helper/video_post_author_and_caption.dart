import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';

import '../../../core/router/app_routes.dart';
import '../../home/cubits/home_cubit/home_cubit.dart';
import '../cubit/posts_cubit/posts_cubit.dart';
import '../model/post_model.dart';
import '../widgets/author_image_widget.dart';
import 'full_screen_video_caption.dart';

class VideoPostAuthorAndCaption extends StatelessWidget {
  final PostModel post;
  final PostsCubit postsCubit;
  final String currentUserId;
  final VideoPlayerController controller;
  const VideoPostAuthorAndCaption(
    BuildContext context, {
    super.key,
    required this.post,
    required this.postsCubit,
    required this.currentUserId,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostsCubit, PostsState>(
      bloc: postsCubit,
      buildWhen: (prev, curr) => prev is PostsLoaded && curr is PostsLoaded,
      builder: (context, state) {
        final currentPost =
            (state is PostsLoaded)
                ? state.posts.findById(post.id) ?? post
                : post;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AuthorImageWidget(
                  authorImageSize: 32,
                  post: currentPost,
                  showBorder: false,
                  showDot: false,
                  onTap: () => _handleAuthorTap(context, currentPost),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _handleAuthorTap(context, currentPost),
                    child: Text(
                      currentPost.authorName ?? 'Unknown',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black87)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (currentPost.text.trim().isNotEmpty)
              Column(
                children: [
                  FullScreenVideoCaption(text: currentPost.text),
                  const SizedBox(height: 14),
                ],
              )
            else ...[
              const SizedBox(height: 22),
            ],
          ],
        );
      },
    );
  }

  void _handleAuthorTap(BuildContext context, PostModel post) {
    if (controller.value.isPlaying) {
      controller.pause();
    }

    final bool isOwnPost = post.authorId == currentUserId;
    final navigator = Navigator.of(context, rootNavigator: true);

    Navigator.of(context).pop();

    if (isOwnPost) {
      context.read<HomeCubit>().navController?.jumpToTab(3);
    } else {
      navigator.pushNamed(AppRoutes.profileViewRoute, arguments: post.authorId);
    }
  }
}
