import 'package:flutter/material.dart';
import '../../gifs/utils/loop_limited_gif.dart';

class CreatePostGifPreview extends StatelessWidget {
  final String gifUrl;
  final double aspectRatio;
  final VoidCallback onRemove;

  const CreatePostGifPreview({
    super.key,
    required this.gifUrl,
    required this.aspectRatio,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: aspectRatio.clamp(0.6, 2.2),
              child: LoopLimitedGif(
                key: ValueKey(gifUrl),
                url: gifUrl,
                maxLoops: 3,
                fit: BoxFit.cover,
              ),
            ),
          ),
          PositionedDirectional(
            start: 8,
            top: 8,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
