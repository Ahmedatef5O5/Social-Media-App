import 'package:flutter/material.dart';
import 'package:social_media_app/core/widgets/app_avatar.dart';
import '../../../core/presence/widgets/presence_avatar_widget.dart';

class UserChatAvatar extends StatelessWidget {
  final String userId;
  final String? userImgUrl;

  const UserChatAvatar({
    super.key,
    required this.userId,
    required this.userImgUrl,
  });

  @override
  Widget build(BuildContext context) {
    return PresenceAvatarWidget(
      userId: userId,
      avatarSize: 28,
      showBorder: false,
      child: AppAvatar(imageUrl: userImgUrl, size: 28),
    );
  }
}
