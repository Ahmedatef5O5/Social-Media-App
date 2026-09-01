import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/cached_cloudinary_image.dart';
import '../../group_chats/helpers/group_navigation.dart';
import '../models/shared_group_item.dart';

class SharedGroupTile extends StatelessWidget {
  final SharedGroupItem item;
  const SharedGroupTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final group = item.group;
    final hasAvatar = group.avatarUrl != null && group.avatarUrl!.isNotEmpty;
    final primary = Theme.of(context).primaryColor;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        openGroupChat(
          group.id,
          () => Navigator.of(
            context,
            rootNavigator: true,
          ).pushNamed(AppRoutes.groupChatRoute, arguments: group),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            ClipOval(
              child: Container(
                width: 44,
                height: 44,
                color: primary.withValues(alpha: 0.12),
                child:
                    hasAvatar
                        ? CachedCloudinaryImage(
                          secureUrl: group.avatarUrl!,
                          fit: BoxFit.cover,
                          isAvatar: true,
                        )
                        : Center(
                          child: Image.asset(
                            AppImages.defaultGroupImg,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
              ),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    '${item.membersCount} ${item.membersCount == 1 ? 'member' : 'members'}',
                    style: TextStyle(fontSize: 12.5, color: AppColors.grey4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
