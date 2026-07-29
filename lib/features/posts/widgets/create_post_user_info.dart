import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/widgets/main_user_avatar.dart';
import '../../social_graph/models/content_privacy.dart';
import '../../social_graph/widgets/privacy_chip.dart';

class CreatePostUserInfo extends StatelessWidget {
  final String userName;
  final String? userImageUrl;
  final ContentPrivacy privacy;
  final VoidCallback onPrivacyTap;

  const CreatePostUserInfo({
    super.key,
    required this.userName,
    this.userImageUrl,
    required this.privacy,
    required this.onPrivacyTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Hero(
          tag: 'user-avatar-hero',
          child: MainUserAvatar(
            imageUrl: userImageUrl,
            size: 48,
            showBorder: true,
          ),
        ),

        Gap(12),
        Text(
          userName,
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w400,
          ),
        ),
        Spacer(),

        PrivacyChip(privacy: privacy, onTap: onPrivacyTap),
      ],
    );
  }
}
