import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';
import 'package:social_media_app/core/widgets/app_avatar.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/widgets/cached_cloudinary_image.dart';
import '../../group_chats/models/group_model.dart';

/// Header of CreatePostView when posting inside a group:
/// "Creating in [group avatar] [group name]" + a locked "Group members" chip.
class CreatePostGroupTargetHeader extends StatelessWidget {
  final GroupModel group;
  final String userName;
  final String? userImageUrl;

  const CreatePostGroupTargetHeader({
    super.key,
    required this.group,
    required this.userName,
    this.userImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAvatar = group.avatarUrl != null && group.avatarUrl!.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 54,
          height: 54,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child:
                      hasAvatar
                          ? CachedCloudinaryImage(
                            secureUrl: group.avatarUrl!,
                            fit: BoxFit.cover,
                            isAvatar: true,
                          )
                          : Image.asset(
                            AppImages.defaultGroupImg,
                            fit: BoxFit.cover,
                          ),
                ),
              ),
              PositionedDirectional(
                bottom: 0,
                end: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.scaffoldBackgroundColor,
                      width: 2,
                    ),
                  ),
                  child: AppAvatar(imageUrl: userImageUrl, size: 22),
                ),
              ),
            ],
          ),
        ),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n.creatingIn(group.name),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium!.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                  letterSpacing: context.ls(0),
                ),
              ),
              const Gap(4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 13,
                      color: theme.primaryColor,
                    ),
                    const Gap(4),
                    Text(
                      context.l10n.groupMembersOnly,
                      style: theme.textTheme.titleSmall!.copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: theme.primaryColor,
                        letterSpacing: context.ls(0),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
