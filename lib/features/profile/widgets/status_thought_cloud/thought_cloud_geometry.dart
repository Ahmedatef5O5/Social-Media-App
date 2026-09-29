import 'package:flutter/widgets.dart';

class ThoughtCloudGeometry {
  const ThoughtCloudGeometry({required this.avatarRect});

  final Rect avatarRect;

  static const Alignment _avatarAlignment = Alignment(-0.85, 0.99);

  factory ThoughtCloudGeometry.fromProfileHeader({
    required double screenWidth,
    required double backgroundHeight,
    required double avatarSize,
  }) {
    final double parentHeight = backgroundHeight + avatarSize / 2;

    final double left =
        (screenWidth - avatarSize) / 2 * (1 + _avatarAlignment.x);
    final double top =
        (parentHeight - avatarSize) / 2 * (1 + _avatarAlignment.y);

    return ThoughtCloudGeometry(
      avatarRect: Rect.fromLTWH(left, top, avatarSize, avatarSize),
    );
  }

  Offset get originOnAvatarEdge =>
      Offset(avatarRect.right, avatarRect.center.dy);
}
