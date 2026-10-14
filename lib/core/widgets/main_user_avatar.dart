import 'package:flutter/material.dart';
import 'package:social_media_app/core/widgets/app_avatar.dart';
import '../presence/widgets/presence_avatar_widget.dart';

class MainUserAvatar extends StatelessWidget {
  final String? userId;
  final String? imageUrl;
  final double? size;
  final bool showBorder;
  final bool isDeleted;
  const MainUserAvatar({
    super.key,
    this.userId,
    this.imageUrl,
    this.size = 36,
    this.showBorder = false,
    this.isDeleted = false,
  });

  @override
  Widget build(BuildContext context) {
    return PresenceAvatarWidget(
      userId: userId ?? '',
      avatarSize: size ?? 31,
      showDot: !isDeleted,
      showBorder: false,

      child: AppAvatar(
        imageUrl: isDeleted ? null : imageUrl,
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
