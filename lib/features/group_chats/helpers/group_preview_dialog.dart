import 'package:social_media_app/core/widgets/cached_cloudinary_image.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../models/group_model.dart';

class GroupPreviewDialog extends StatelessWidget {
  final GroupModel group;

  const GroupPreviewDialog({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final hasAvatar = group.avatarUrl != null && group.avatarUrl!.isNotEmpty;

    const String defaultGroupImage = AppImages.defaultGroupImg;

    final screenSize = MediaQuery.sizeOf(context);
    final horizontalInset = (screenSize.width * 0.14).clamp(45.0, 80.0);
    final dialogWidth = screenSize.width - (horizontalInset * 2);
    final imageHeight = dialogWidth;

    return Dialog(
      alignment: const Alignment(0, -0.55),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: horizontalInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Hero(
            tag: group.id,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context, rootNavigator: true).pushNamed(
                  AppRoutes.fullScreenImageViewRoute,
                  arguments: {
                    'url': hasAvatar ? group.avatarUrl! : defaultGroupImage,
                    'tag': group.id,
                    'isAsset': !hasAvatar,
                  },
                );
              },
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Stack(
                  children: [
                    hasAvatar
                        ? CachedCloudinaryImage(
                          secureUrl: group.avatarUrl!,
                          fit: BoxFit.cover,
                          height: imageHeight,
                          width: double.infinity,
                          isAvatar: true,
                          placeholder:
                              (context) => SizedBox(
                                height: imageHeight,
                                child: const Center(
                                  child: CustomLoadingIndicator(),
                                ),
                              ),
                          errorWidget:
                              (context, error) => Image.asset(
                                defaultGroupImage,
                                fit: BoxFit.cover,
                                height: imageHeight,
                                width: double.infinity,
                              ),
                        )
                        : Image.asset(
                          defaultGroupImage,
                          fit: BoxFit.cover,
                          height: imageHeight,
                          width: double.infinity,
                        ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.5),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Text(
                          group.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: Icon(Icons.message_outlined, color: primary),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(
                      context,
                      rootNavigator: true,
                    ).pushNamed(AppRoutes.groupChatRoute, arguments: group);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.group_outlined, color: primary),
                  onPressed: () {
                    Navigator.of(
                      context,
                      rootNavigator: true,
                    ).pushNamed(AppRoutes.groupInfoViewRoute, arguments: group);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
