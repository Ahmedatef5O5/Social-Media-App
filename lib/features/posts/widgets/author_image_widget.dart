import 'package:flutter/material.dart';
import '../../../core/presence/widgets/presence_avatar_widget.dart';
import '../models/post_model.dart';
import '../../../core/widgets/app_avatar.dart';

class AuthorImageWidget extends StatelessWidget {
  const AuthorImageWidget({
    super.key,
    required this.post,
    required this.onTap,
    this.authorImageSize = 44,
    this.showBorder,
    this.showDot,
  });

  final PostModel post;
  final void Function()? onTap;
  final double? authorImageSize;
  final bool? showBorder, showDot;

  @override
  Widget build(BuildContext context) {
    return PresenceAvatarWidget(
      userId: post.authorId,
      avatarSize: authorImageSize ?? 44,
      showBorder: showBorder ?? true,
      showDot: showBorder ?? true,
      child: AppAvatar(
        imageUrl: post.authorImageUrl,
        size: authorImageSize ?? 44,
        onTap: onTap,
      ),
    );
  }
}
