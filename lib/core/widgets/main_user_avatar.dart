import 'package:flutter/material.dart';
import 'package:social_media_app/core/widgets/app_avatar.dart';

class MainUserAvatar extends StatelessWidget {
  final String? imageUrl;
  final double? size;
  final bool showBorder;
  const MainUserAvatar({
    super.key,
    this.imageUrl,
    this.size = 36,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppAvatar(
      imageUrl: imageUrl,
      size: size ?? 36,
      borderColor:
          showBorder
              ? Theme.of(context).primaryColor.withValues(alpha: 0.8)
              : null,
      borderWidth: 2.2,
    );
  }
}
