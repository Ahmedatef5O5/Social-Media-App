import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/router/app_routes.dart';
import '../../chats/models/chat_user_model.dart';
import '../../profile/widgets/user_preview_dialog.dart';
import '../model/comment_model.dart';

class CommentAvatar extends StatelessWidget {
  final CommentModel comment;
  final String? imageUrl;
  final double radius;

  const CommentAvatar({
    super.key,
    required this.comment,
    required this.imageUrl,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser!.id;
    bool isCommentedByMe = comment.authorId == currentUserId;

    return GestureDetector(
      onTap:
          isCommentedByMe
              ? () {
                Navigator.of(context, rootNavigator: true).pushNamed(
                  AppRoutes.fullScreenImageViewRoute,
                  arguments: {
                    'url':
                        (comment.authorImageUrl != null &&
                                comment.authorImageUrl!.isNotEmpty)
                            ? comment.authorImageUrl!
                            : AppImages.defaultUserImg,
                    'tag': comment.authorId,
                    'isAsset':
                        comment.authorImageUrl == null ||
                        comment.authorImageUrl!.isEmpty,
                  },
                );
              }
              : () {
                final user = ChatUserModel(
                  id: comment.authorId,
                  name: comment.authorName ?? 'Unknown',
                  imageUrl: comment.authorImageUrl,
                );
                showDialog(
                  context: context,
                  builder:
                      (context) => UserPreviewDialog(
                        user: user,
                        showContactOptions: false,
                      ),
                );
              },
      child: Hero(
        tag: comment.authorId,
        child: CircleAvatar(
          radius: radius,
          backgroundImage:
              (imageUrl != null && imageUrl!.isNotEmpty)
                  ? CachedNetworkImageProvider(imageUrl!)
                  : const AssetImage(AppImages.defaultUserImg),
        ),
      ),
    );
  }
}
