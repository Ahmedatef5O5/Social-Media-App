import 'package:flutter/material.dart';
import '../../posts/model/post_model.dart';
import '../../../core/widgets/app_avatar.dart';

class AuthorImageWidget extends StatelessWidget {
  const AuthorImageWidget({super.key, required this.post, required this.onTap});

  final PostModel post;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final isOnline = post.isOnline;

    return AppAvatar(
      imageUrl: post.authorImageUrl,
      size: 44,
      onTap: onTap,
      isOnline: isOnline,
      showOnlineDot: isOnline,
      borderColor: isOnline ? Colors.green : null,
      borderWidth: 2.2,
    );
  }
}
