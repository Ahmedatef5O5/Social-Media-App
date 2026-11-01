import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/widgets/main_user_avatar.dart';
import '../../social_graph/models/content_privacy.dart';
import '../../social_graph/widgets/privacy_chip.dart';
import '../../group_chats/models/group_model.dart';
import 'create_post_group_target_header.dart';

class CreatePostUserInfo extends StatelessWidget {
  final String userName;
  final String? userImageUrl;
  final ContentPrivacy privacy;
  final VoidCallback onPrivacyTap;
  final GroupModel? targetGroup;

  const CreatePostUserInfo({
    super.key,
    required this.userName,
    this.userImageUrl,
    required this.privacy,
    required this.onPrivacyTap,
    this.targetGroup,
  });

  @override
  Widget build(BuildContext context) {
    if (targetGroup != null) {
      return CreatePostGroupTargetHeader(
        group: targetGroup!,
        userName: userName,
        userImageUrl: userImageUrl,
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Hero(
          tag: 'user-avatar-hero',
          child: MainUserAvatar(
            imageUrl: userImageUrl,
            size: 48,
            showBorder: true,
          ),
        ),
        const Gap(12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              userName,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.15,
              ),
            ),
            const Gap(3),
            // تحديد الارتفاع الفعلي داخل الـ Layout ليطابق حجم الأيقونة والنص
            SizedBox(
              height: 22,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: PrivacyChip(privacy: privacy, onTap: onPrivacyTap),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
