import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:social_media_app/core/constants/app_images.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
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
    // debugPrint("Post ID: ${post.id} | Video URL: ${post.videoUrl}");
    final user = context.read<HomeCubit>().currentUserData;
    final authUser = Supabase.instance.client.auth.currentUser;
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
                    user?.imageUrl != null
                        ? CachedNetworkImageProvider(user!.imageUrl!)
                        : (authUser?.userMetadata?['avatar_url'] != null)
                        ? CachedNetworkImageProvider(
                          authUser!.userMetadata!['avatar_url'],
                        )
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
                            // 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQeJQeJyzgAzTEVqXiGe90RGBFhfp_4RcJJMQ&s',
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

            // _buildVideoPlayer(post.videoUrl!),
            if (post.fileUrl != null && post.fileUrl!.isNotEmpty)
              FileAttachmentPreview(url: post.fileUrl!, onTap: () {}),
            Gap(12),
            Row(
              children: [
                Gap(12),
                InkWell(
                  onTap: () {},
                  child: Row(
                    children: [
                      Icon(Icons.thumb_up_alt_outlined),
                      Gap(4),
                      Text(
                        post.likes?.length.toString() ?? '0',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                Gap(12),
                InkWell(
                  onTap: () {},
                  child: Row(
                    children: [
                      Icon(Icons.mode_comment_outlined),
                      Gap(4),
                      Text(
                        post.comments?.length.toString() ?? '0',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                Gap(12),
                Icon(Icons.share_outlined),
                Spacer(),
                Icon(Icons.save_outlined),
                Gap(8),
              ],
            ),
            Gap(8),
          ],
        ),
      ),
    );
  }
}
