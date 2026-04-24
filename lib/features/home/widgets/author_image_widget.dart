import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../models/post_model.dart';

class AuthorImageWidget extends StatelessWidget {
  const AuthorImageWidget({super.key, required this.post, required this.onTap});
  final PostModel post;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    // ✅ Use isOnline field stamped onto PostModel
    final isOnline = post.isOnline;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Avatar with green border when online
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              // ✅ Green ring when online
              border:
                  isOnline ? Border.all(color: Colors.green, width: 2.2) : null,
            ),
            child: ClipOval(
              child:
                  (post.authorImageUrl != null &&
                          post.authorImageUrl!.isNotEmpty)
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
                      : Image.asset(
                        AppImages.defaultUserImg,
                        fit: BoxFit.cover,
                      ),
            ),
          ),

          // ✅ Green dot indicator — bottom-right corner
          if (isOnline)
            Positioned(
              bottom: 1,
              right: 1,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
