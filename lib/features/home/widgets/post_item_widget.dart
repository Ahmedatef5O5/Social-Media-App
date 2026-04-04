import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import 'package:social_media_app/features/home/widgets/post_header_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../cubit/home_cubit.dart';
import '../models/post_model.dart';
import 'post_interactions_row.dart';
import 'post_media_widget.dart';
import 'post_txt_content_widget.dart';

class PostItemWidget extends StatelessWidget {
  const PostItemWidget({super.key, required this.currPost});
  final PostModel currPost;

  @override
  Widget build(BuildContext context) {
    final homeCubit = context.read<HomeCubit>();

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return SizedBox.shrink();

    return BlocBuilder<HomeCubit, HomeState>(
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
              oldPost.likersImages?.length != newPost.likersImages?.length;
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
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              width: 1,
              color: AppColors.blueGrey4.withValues(alpha: 0.35),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PostHeaderWidget(
                  post: currentPost,
                  currentUserId: currentUserId,
                  homeCubit: homeCubit,
                ),
                PostTxtContentWidget(post: currentPost),
                PostMediaWidget(post: currentPost),
                PostInteractionsRow(
                  currentPost: currentPost,
                  currUserId: currentUserId,
                  homeCubit: homeCubit,
                  post: currentPost,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
