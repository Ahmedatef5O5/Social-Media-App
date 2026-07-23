import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/widgets/main_user_avatar.dart';
import '../../social_graph/models/content_privacy.dart';

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

  String get _label => switch (privacy) {
    ContentPrivacy.public => 'Public',
    ContentPrivacy.friends => 'Friends',
    ContentPrivacy.private => 'Private',
  };

  IconData get _icon => switch (privacy) {
    ContentPrivacy.public => Icons.public,
    ContentPrivacy.friends => Icons.people_alt_rounded,
    ContentPrivacy.private => Icons.lock_outline,
  };

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
        InkWell(
          borderRadius: BorderRadius.circular(3),
          onTap: onPrivacyTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                width: 1.2,
                color: Theme.of(context).primaryColor,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              child: Row(
                children: [
                  Icon(_icon, size: 14, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    _label,
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down_outlined, size: 26),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
