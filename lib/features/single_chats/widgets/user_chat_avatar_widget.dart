import 'package:flutter/material.dart';
import 'package:social_media_app/core/widgets/app_avatar.dart';

class UserChatAvatar extends StatelessWidget {
  final String? userImgUrl;

  const UserChatAvatar({super.key, required this.userImgUrl});

  @override
  Widget build(BuildContext context) {
    return AppAvatar(imageUrl: userImgUrl, size: 28);
  }
}
