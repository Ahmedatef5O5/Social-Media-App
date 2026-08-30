import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../reels/models/reel_model.dart';

class ReelGridTile extends StatelessWidget {
  final ReelModel reel;
  final VoidCallback onTap;

  const ReelGridTile({super.key, required this.reel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: reel.thumbnailUrl,
            fit: BoxFit.cover,
            placeholder:
                (_, __) =>
                    Container(color: Colors.black.withValues(alpha: 0.06)),
            errorWidget: (_, __, ___) => Container(color: Colors.black26),
          ),
          const Positioned(
            top: 6,
            right: 6,
            child: Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 20,
              shadows: [Shadow(blurRadius: 6, color: Colors.black87)],
            ),
          ),
          Positioned(
            left: 6,
            right: 6,
            bottom: 6,
            child: Row(
              children: [
                const Icon(
                  Icons.remove_red_eye_rounded,
                  color: Colors.white,
                  size: 12,
                ),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    _formatViews(reel.originalViewCount),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black87)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatViews(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }
}
