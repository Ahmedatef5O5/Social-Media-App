import 'package:flutter/material.dart';
import '../app_avatar.dart';
import 'active_call_header_content.dart';

class CallHeaderAvatarWithBadge extends StatelessWidget {
  const CallHeaderAvatarWithBadge({
    super.key,
    required this.widget,
    required this.accent,
  });

  final ActiveCallHeaderContent widget;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AppAvatar(
          imageUrl: session.avatarUrl,
          size: 32,
          borderColor: accent,
          borderWidth: 1.5,
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 13,
            height: 13,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent,
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.2),
                width: 1.3,
              ),
            ),
            child: Icon(
              session.isVideo ? Icons.videocam_rounded : Icons.call_rounded,
              size: 6,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
