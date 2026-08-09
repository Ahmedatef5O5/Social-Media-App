import 'package:flutter/material.dart';
import 'cached_cloudinary_image.dart';

class OverlappingAvatarStack extends StatelessWidget {
  final List<String?> avatarUrls;
  final double size;
  final double overlapFraction;
  final int maxVisible;

  const OverlappingAvatarStack({
    super.key,
    required this.avatarUrls,
    this.size = 22,
    this.overlapFraction = 0.55,
    this.maxVisible = 3,
  });

  @override
  Widget build(BuildContext context) {
    final visible = avatarUrls.take(maxVisible).toList();
    final extraCount = avatarUrls.length - visible.length;
    final step = size * (1 - overlapFraction);
    final totalWidth =
        step * (visible.length - 1 + (extraCount > 0 ? 1 : 0)) + size;

    return SizedBox(
      height: size,
      width: totalWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = visible.length - 1; i >= 0; i--)
            Positioned(
              left: i * step,
              child: _Bubble(size: size, url: visible[i]),
            ),
          if (extraCount > 0)
            Positioned(
              left: visible.length * step,
              child: _Bubble(size: size, extraCount: extraCount),
            ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final double size;
  final String? url;
  final int? extraCount;
  const _Bubble({required this.size, this.url, this.extraCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).scaffoldBackgroundColor,
          width: 2,
        ),
        color: Colors.grey.shade300,
      ),
      child: ClipOval(
        child:
            extraCount != null
                ? Center(
                  child: Text(
                    '+$extraCount',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
                : (url != null
                    ? CachedCloudinaryImage(
                      secureUrl: url!,
                      fit: BoxFit.cover,
                      isAvatar: true,
                    )
                    : const Icon(Icons.person, size: 12)),
      ),
    );
  }
}
