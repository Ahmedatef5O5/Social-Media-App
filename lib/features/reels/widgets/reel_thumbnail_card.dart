import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/helpers/chat_helper.dart';
import '../models/reel_model.dart';

class ReelThumbnailCard extends StatelessWidget {
  final ReelModel reel;
  final VoidCallback onTap;
  const ReelThumbnailCard({super.key, required this.reel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textDirection = ChatHelper.getTextDirection(reel.title);
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
                errorWidget:
                    (context, url, error) => Container(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported_rounded,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                          size: 32,
                        ),
                      ),
                    ),
              ),
              const Positioned(
                top: 4,
                left: 4,
                child: Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Directionality(
                  textDirection: textDirection,
                  child: Text(
                    reel.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textDirection: textDirection,
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                    ),
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
