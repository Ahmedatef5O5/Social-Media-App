import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/core/constants/app_images.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import 'package:social_media_app/features/chats/models/chat_user_model.dart';
import '../../../core/router/app_routes.dart';

class UserPreviewDialog extends StatelessWidget {
  final ChatUserModel user;
  final bool showContactOptions;
  const UserPreviewDialog({
    super.key,
    required this.user,
    this.showContactOptions = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).primaryColor;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      backgroundColor: Colors.transparent,

      insetPadding: const EdgeInsets.symmetric(horizontal: 50),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Hero(
            tag: user.id,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    child:
                        (user.imageUrl != null && user.imageUrl!.isNotEmpty)
                            ? CachedNetworkImage(
                              imageUrl: user.imageUrl!,
                              fit: BoxFit.cover,
                              height: 300,
                              width: double.infinity,
                              placeholder:
                                  (context, url) => SizedBox(
                                    height: 300,
                                    child: const Center(
                                      child: CustomLoadingIndicator(),
                                    ),
                                  ),
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
                        user.name,
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
                  icon: Icon(Icons.message_outlined, color: iconColor),
                  onPressed: () {
                    Navigator.pop(context);

                    Navigator.of(context, rootNavigator: true).pushNamed(
                      AppRoutes.chatDetailsViewRoute,
                      arguments: user,
                    );
                  },
                ),
                if (showContactOptions) ...[
                  IconButton(
                    icon: Icon(Icons.call_outlined, color: iconColor),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.videocam_outlined, color: iconColor),
                    onPressed: () {},
                  ),
                ],
                IconButton(
                  icon: Icon(Icons.info_outline, color: iconColor),
                  onPressed: () {
                    Navigator.of(
                      context,
                      rootNavigator: true,
                    ).pushNamed(AppRoutes.profileViewRoute, arguments: user.id);
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
