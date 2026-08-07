import 'dart:ui';
import 'package:flutter/material.dart';
import 'call_gradient_background.dart';
import '../cached_cloudinary_image.dart';

class CallAvatarBackdrop extends StatelessWidget {
  final String? avatarUrl;
  final Color baseColor;

  const CallAvatarBackdrop({
    super.key,
    required this.avatarUrl,
    required this.baseColor,
  });

  bool get _hasPhoto => avatarUrl != null && avatarUrl!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (!_hasPhoto) {
      return CallGradientBackground(baseColor: baseColor);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Transform.scale(
          scale: 1.18,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
            child: CachedCloudinaryImage(
              secureUrl: avatarUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorWidget:
                  (_, __) => CallGradientBackground(baseColor: baseColor),
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                baseColor.withValues(alpha: 0.50),
                baseColor.withValues(alpha: 0.28),
                Colors.black.withValues(alpha: 0.55),
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}
