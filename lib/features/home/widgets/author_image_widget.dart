import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../../profile/widgets/user_preview_dialog.dart';
import '../models/post_model.dart';

class AuthorImageWidget extends StatelessWidget {
  const AuthorImageWidget({super.key, required this.post});
  final PostModel post;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder:
              (context) => UserPreviewDialog(
                user: post.toChatUserModel(),
                showContactOptions: false,
              ),
        );
      },
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child:
              (post.authorImageUrl != null && post.authorImageUrl!.isNotEmpty)
                  ? CachedNetworkImage(
                    imageUrl: post.authorImageUrl!,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => const CustomLoadingIndicator(),
                    errorWidget:
                        (context, url, error) => Image.asset(
                          AppImages.defaultUserImg,
                          fit: BoxFit.cover,
                        ),
                  )
                  : Image.asset(AppImages.defaultUserImg, fit: BoxFit.cover),
        ),
      ),
    );
  }
}
