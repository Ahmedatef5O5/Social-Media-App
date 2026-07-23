import 'package:flutter/material.dart';
import 'package:social_media_app/core/widgets/app_avatar.dart';
import '../presence/widgets/presence_avatar_widget.dart';

class MainUserAvatar extends StatelessWidget {
  final String? userId;
  final String? imageUrl;
  final double? size;
  final bool showBorder;
  const MainUserAvatar({
    super.key,
    this.userId,
    this.imageUrl,
    this.size = 36,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return PresenceAvatarWidget(
      userId: userId ?? '',
      avatarSize: size ?? 31,
      showDot: true,
      showBorder: false,

      child: AppAvatar(
        imageUrl: imageUrl,
        size: size ?? 31,
        borderColor:
            showBorder
                ? Theme.of(context).primaryColor.withValues(alpha: 0.8)
                : null,
        borderWidth: 2.2,
      ),
    );
  }
}
