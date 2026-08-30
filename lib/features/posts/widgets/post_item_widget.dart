import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/features/posts/widgets/post_header_widget.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../cubits/posts_cubit/posts_cubit.dart';
import '../helpers/header_trailing_action.dart';
import '../models/post_details_route_args.dart';
import '../models/post_model.dart';
import '../../reels/widgets/shared_reel_preview_card.dart';
import '../views/post_details_view.dart';
import 'post_interactions_row.dart';
import 'post_media_widget.dart';
import 'post_txt_content_widget.dart';
import 'shared_post_header_widget.dart';

class PostItemWidget extends StatelessWidget {
  final PostModel currPost;
  final PostsCubit postsCubit;
  const PostItemWidget({
    super.key,
    required this.currPost,
    required this.postsCubit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentUserId = SupabaseProvider.id;

    return BlocBuilder<PostsCubit, PostsState>(
      buildWhen: (previous, current) {
        if (previous is PostsLoaded && current is PostsLoaded) {
          final bool stillExists = current.posts.any(
            (p) => p.id == currPost.id,
          );
          if (!stillExists) return false;

          final oldPost = previous.posts.firstWhere((p) => p.id == currPost.id);
          final newPost = current.posts.firstWhere((p) => p.id == currPost.id);

          return oldPost.likesCount != newPost.likesCount ||
              oldPost.isLikedBy(currentUserId) !=
                  newPost.isLikedBy(currentUserId) ||
              oldPost.reactionsSignature != newPost.reactionsSignature ||
              oldPost.likersImages?.length != newPost.likersImages?.length ||
              oldPost.displayPost.sharesCount !=
                  newPost.displayPost.sharesCount ||
              oldPost.displayPost.isSharedByMe !=
                  newPost.displayPost.isSharedByMe;
        }
        return true;
      },
      builder: (context, state) {
        PostModel currentPost = currPost;
        if (state is PostsLoaded) {
          try {
            currentPost = state.posts.firstWhere((p) => p.id == currentPost.id);
          } catch (_) {
            return const SizedBox.shrink();
          }
        }

        final bool isSharedPost = currentPost.isSharedPost;
        final PostModel? displayPost =
            isSharedPost ? currentPost.originalPost : currentPost;

        if (isSharedPost && displayPost == null) {
          return const SizedBox.shrink();
        }

        final bool isSharedReel = displayPost!.isSharedReel;

        if (isSharedReel && displayPost.sharedReel == null) {
          return const SizedBox.shrink();
        }

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: colorScheme.surface,
            border: Border.all(
              width: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.25),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.of(context, rootNavigator: true).pushNamed(
                  AppRoutes.postDetailsViewRoute,
                  arguments: PostDetailsRouteArgs(
                    post: currentPost,
                    initialActiveMode: PostDetailsActiveMode.comments,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isSharedPost) ...[
                      SharedPostHeaderWidget(
                        sharedPost: currentPost,
                        currentUserId: currentUserId,
                        postsCubit: postsCubit,
                        contentLabel: isSharedReel ? 'a reel' : 'a post',
                        trailingAction: HeaderTrailingAction.moreActions,
                      ),
                      const SizedBox(height: 10),
                    ] else if (isSharedReel) ...[
                      SharedPostHeaderWidget(
                        sharedPost: currentPost,
                        currentUserId: currentUserId,
                        postsCubit: postsCubit,
                        contentLabel: 'a reel',
                        trailingAction: HeaderTrailingAction.moreActions,
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (isSharedReel)
                      SharedReelPreviewCard(reel: displayPost.sharedReel!)
                    else ...[
                      Container(
                        padding:
                            isSharedPost
                                ? const EdgeInsets.all(12)
                                : EdgeInsets.zero,
                        decoration:
                            isSharedPost
                                ? BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      colorScheme.onSurface.withValues(
                                        alpha: 0.03,
                                      ),
                                      colorScheme.onSurface.withValues(
                                        alpha: 0.01,
                                      ),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: colorScheme.outlineVariant
                                        .withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                )
                                : null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PostHeaderWidget(
                              post: displayPost,
                              currentUserId: currentUserId,
                              postsCubit: postsCubit,
                              trailingAction:
                                  isSharedPost
                                      ? HeaderTrailingAction.none
                                      : HeaderTrailingAction.moreActions,
                            ),
                            const SizedBox(height: 8),
                            PostTxtContentWidget(post: displayPost),
                            PostMediaWidget(
                              post: displayPost,
                              postsCubit: postsCubit,
                              currentUserId: currentUserId,
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    PostInteractionsRow(postId: displayPost.id),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
