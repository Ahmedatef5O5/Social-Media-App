import 'package:flutter/material.dart';
import '../../../core/presence/widgets/presence_avatar_widget.dart';
import '../model/post_model.dart';
import '../../../core/widgets/app_avatar.dart';

class AuthorImageWidget extends StatelessWidget {
  const AuthorImageWidget({super.key, required this.post, required this.onTap});

  final PostModel post;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return PresenceAvatarWidget(
      userId: post.authorId,
      avatarSize: 44,
      child: AppAvatar(imageUrl: post.authorImageUrl, size: 44, onTap: onTap),
    );
  }
}
