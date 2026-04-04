import 'package:flutter/material.dart';
import 'package:social_media_app/features/home/widgets/post_actions_menu.dart';
import '../../../core/helpers/formatted_date.dart';
import '../cubit/home_cubit.dart';
import '../models/post_model.dart';
import 'author_image_widget.dart';

class PostHeaderWidget extends StatelessWidget {
  final PostModel post;
  final String currentUserId;
  final HomeCubit homeCubit;
  const PostHeaderWidget({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.homeCubit,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: AuthorImageWidget(post: post),
      title: Text(
        post.authorName ?? 'Unknown',
        style: Theme.of(context).textTheme.titleSmall!.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 18,
        ),
      ),
      subtitle: Text(
        FormattedDate.getFormattedDate(
          DateTime.parse(post.createdAt).toLocal().toIso8601String(),
        ),
        style: Theme.of(context).textTheme.titleSmall!.copyWith(
          fontWeight: FontWeight.w400,
          fontSize: 12,
        ),
      ),
      trailing: PostActionsMenu(
        post: post,
        currentUserId: currentUserId,
        homeCubit: homeCubit,
      ),
    );
  }
}
