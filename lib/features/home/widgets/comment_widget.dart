import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/constants/app_images.dart';
import 'package:social_media_app/features/home/models/comment_model.dart';
import '../../../core/helpers/formatted_date.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/custom_loading_indicator.dart';

class CommentWidget extends StatelessWidget {
  final CommentModel comment;
  final String postId;

  const CommentWidget({super.key, required this.comment, required this.postId});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundImage:
                  (comment.authorImageUrl != null &&
                          comment.authorImageUrl!.isNotEmpty)
                      ? CachedNetworkImageProvider(
                        comment.authorImageUrl!,
                        errorListener: (_) => const CustomLoadingIndicator(),
                      )
                      : AssetImage(AppImages.defaultUserImg),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.grey3,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.authorName ?? 'UserName',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.black87,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 4),
                      Text(
                        comment.text,
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          color: AppColors.grey9,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.reply),
                  onPressed: () {
                    // Handle reply action
                  },
                ),
                Text(
                  'Reply',
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    color: AppColors.grey6,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
        Gap(2),
        Align(
          alignment: Alignment.centerRight * 0.75,
          child: Text(
            FormattedDate.getFormattedDate((comment.createdAt), isShort: true),

            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w400,
              color: AppColors.grey8,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}
