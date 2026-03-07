import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import '../models/post_model.dart';

class PostItemWidget extends StatelessWidget {
  const PostItemWidget({super.key, required this.post});
  final PostModel post;

  @override
  Widget build(BuildContext context) {
    // return Card(child: Text(post.text));
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
                    post.imageUrl != null
                        ? CachedNetworkImageProvider(post.imageUrl!)
                        : null,
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
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CachedNetworkImage(
                  imageUrl:
                      post.imageUrl ??
                      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQeJQeJyzgAzTEVqXiGe90RGBFhfp_4RcJJMQ&s',
                  width: 340,
                  // height: 120,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
            ),
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
