import 'package:flutter/material.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/presence/widgets/presence_avatar_widget.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../single_chats/models/chat_user_model.dart';
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
    final currentUserId = SupabaseProvider.id;
    final isMe = comment.authorId == currentUserId;

    return PresenceAvatarWidget(
      userId: comment.authorId,
      avatarSize: radius * 2,
      showBorder: false,
      child: AppAvatar(
        imageUrl: imageUrl,
        size: radius * 2,
        heroTag: comment.authorId,
        onTap: () => isMe ? _openMyAvatar(context) : _showUserPreview(context),
      ),
    );
  }

  void _openMyAvatar(BuildContext context) {
    final url =
        imageUrl?.isNotEmpty == true ? imageUrl! : AppImages.defaultUserImg;

    Navigator.of(context, rootNavigator: true).pushNamed(
      AppRoutes.fullScreenImageViewRoute,
      arguments: {
        'url': url,
        'tag': comment.authorId,
        'isAsset': imageUrl == null || imageUrl!.isEmpty,
      },
    );
  }

  void _showUserPreview(BuildContext context) {
    final user = ChatUserModel(
      id: comment.authorId,
      name: comment.authorName ?? 'Unknown',
      imageUrl: comment.authorImageUrl,
    );
    showDialog(
      context: context,
      builder: (_) => UserPreviewDialog(user: user, showContactOptions: false),
    );
  }
}
