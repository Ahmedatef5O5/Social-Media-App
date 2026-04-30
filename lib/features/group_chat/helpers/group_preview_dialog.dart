import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 50),

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
                    'url': hasAvatar ? group.avatarUrl! : '',
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
                        ? CachedNetworkImage(
                          imageUrl: group.avatarUrl!,
                          fit: BoxFit.cover,
                          height: 300,
                          width: double.infinity,
                          placeholder:
                              (context, url) => const SizedBox(
                                height: 300,
                                child: Center(child: CustomLoadingIndicator()),
                              ),
                          errorWidget:
                              (context, url, error) =>
                                  const Icon(Icons.broken_image),
                        )
                        : Container(
                          height: 300,
                          width: double.infinity,
                          color: primary.withValues(alpha: 0.2),
                          child: Center(
                            child: Text(
                              group.name.isNotEmpty
                                  ? group.name[0].toUpperCase()
                                  : 'G',
                              style: const TextStyle(
                                fontSize: 60,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
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

                // if (showContactOptions) ...[
                // if (false) ...[
                //   IconButton(
                //     icon: Icon(Icons.call_outlined, color: primary),
                //     onPressed: () {},
                //   ),
                //   IconButton(
                //     icon: Icon(Icons.videocam_outlined, color: primary),
                //     onPressed: () {},
                //   ),
                // ],
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
