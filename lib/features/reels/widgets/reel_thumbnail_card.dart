import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../model/reel_model.dart';

class ReelThumbnailCard extends StatelessWidget {
  final ReelModel reel;
  final VoidCallback onTap;
  const ReelThumbnailCard({super.key, required this.reel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 130,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: reel.thumbnailUrl,
                fit: BoxFit.cover,
              ),
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Text(
                  reel.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
