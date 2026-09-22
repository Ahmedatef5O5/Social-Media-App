import 'package:flutter/material.dart';
import '../../../core/widgets/app_avatar.dart';

class ProfileAvatarStack extends StatelessWidget {
  final List<String?> imageUrls;
  final double size;
  final double overlap;
  final Color ringColor;
  final double ringWidth;

  const ProfileAvatarStack({
    super.key,
    required this.imageUrls,
    required this.ringColor,
    this.size = 28,
    this.overlap = 8,
    this.ringWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();

    final double outer = size + ringWidth * 2;
    final double step = outer - overlap;
    final double totalWidth = outer + (imageUrls.length - 1) * step;

    return SizedBox(
      width: totalWidth,
      height: outer,
      child: Stack(
        children: [
          for (var i = 0; i < imageUrls.length; i++)
            Positioned(
              left: i * step,
              child: Container(
                padding: EdgeInsets.all(ringWidth),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ringColor,
                ),
                child: AppAvatar(imageUrl: imageUrls[i], size: size),
              ),
            ),
        ],
      ),
    );
  }
}
