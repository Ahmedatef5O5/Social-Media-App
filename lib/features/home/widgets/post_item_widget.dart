import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:social_media_app/core/constants/app_images.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import 'package:social_media_app/features/home/widgets/comments_sheet_section.dart';
import 'package:social_media_app/features/home/widgets/file_attachment_preview.dart';
import 'package:social_media_app/features/home/widgets/post_video_player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../cubit/home_cubit.dart';
import '../models/post_model.dart';

class PostItemWidget extends StatelessWidget {
  const PostItemWidget({super.key, required this.post});
  final PostModel post;

  @override
  Widget build(BuildContext context) {
    final homeCubit = context.read<HomeCubit>();

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return SizedBox.shrink();

    return BlocBuilder<HomeCubit, HomeState>(
      buildWhen: (previous, current) {
        if (previous is PostsLoaded && current is PostsLoaded) {
          final oldPost = previous.posts.firstWhere((p) => p.id == post.id);
          final newPost = current.posts.firstWhere((p) => p.id == post.id);
          return oldPost.likesCount != newPost.likesCount ||
              oldPost.isLikedBy(userId) != newPost.isLikedBy(userId) ||
              oldPost.likersImages?.length != newPost.likersImages?.length;
        }
        return true;
      },
      builder: (context, state) {
        PostModel currentPost = post;
        if (state is PostsLoaded) {
          currentPost = state.posts.firstWhere(
            (p) => p.id == post.id,
            orElse: () => post,
          );
        }
        return Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(width: 1, color: AppColors.blueGrey1),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.bgColor2,
                    backgroundImage:
                        post.authorImageUrl != null &&
                                post.authorImageUrl!.isNotEmpty
                            ? CachedNetworkImageProvider(post.authorImageUrl!)
                            : const CachedNetworkImageProvider(
                                  AppImages.defaultUserImg,
                                )
                                as ImageProvider, // backgroundImage:
                  ),
                  title: Text(
                    post.authorName ?? 'Unknown',
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text(
                    DateFormat('h:mm a').format(DateTime.parse(post.createdAt)),

                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      fontWeight: FontWeight.w400,
                      fontSize: 13,
                      color: AppColors.black54,
                    ),
                  ),
                ),
                Gap(4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    post.text,
                    textAlign: TextAlign.start,
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      // color: AppColors.black54,
                    ),
                  ),
                ),
                Gap(8),
                if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child:
                          post.imageUrl != null
                              ? CachedNetworkImage(
                                imageUrl: post.imageUrl!,
                                width: 350,
                                height: 220,
                                fit: BoxFit.fill,
                                placeholder:
                                    (context, url) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                errorWidget:
                                    (context, url, error) =>
                                        const Icon(Icons.error),
                              )
                              : null,
                    ),
                  ),
                if (post.videoUrl != null && post.videoUrl!.isNotEmpty)
                  PostVideoPlayer(videoUrl: post.videoUrl!),

                if (post.fileUrl != null && post.fileUrl!.isNotEmpty)
                  FileAttachmentPreview(url: post.fileUrl!, onTap: () {}),
                Gap(12),

                Row(
                  children: [
                    Gap(12),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => homeCubit.toggleLike(currentPost),
                          icon: AnimatedSwitcher(
                            key: ValueKey<bool>(currentPost.isLikedBy(userId)),
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              currentPost.isLikedBy(userId)
                                  ? Icons.thumb_up_alt
                                  : Icons.thumb_up_alt_outlined,
                              color:
                                  currentPost.isLikedBy(userId)
                                      ? AppColors.primaryColor
                                      : AppColors.grey6,
                            ),
                          ),
                        ),
                        Gap(4),
                        Text(
                          '${currentPost.likesCount}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),

                    Gap(12),
                    InkWell(
                      onTap: () {
                        final homeCubit = context.read<HomeCubit>();
                        showModalBottomSheet(
                          context: context,
                          useRootNavigator: true,
                          isScrollControlled: true,
                          backgroundColor: AppColors.white,
                          useSafeArea: false,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          builder:
                              (BuildContext context) => BlocProvider.value(
                                value: homeCubit,
                                child: CommentsSheetSection(postId: post.id),
                              ),
                        );
                      },
                      child: Row(
                        children: [
                          Image.asset(
                            AppImages.commentAtPostIcon,
                            width: 24,
                            height: 24,
                          ),

                          Gap(4),
                          Text(
                            '${currentPost.comments?.length ?? 0}',

                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                    Gap(12),
                    Image.asset(AppImages.sharePostIcon, width: 24, height: 24),

                    Spacer(),
                    Image.asset(AppImages.savePostIcon, width: 24, height: 24),

                    Gap(8),
                  ],
                ),

                Gap(8),
              ],
            ),
          ),
        );
      },
    );
  }
}
