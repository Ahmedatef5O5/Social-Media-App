import 'package:flutter/material.dart';
import '../utils/animated_loop_cloudinary_sticker.dart';

class StickerMessageBubble extends StatelessWidget {
  final String url;
  const StickerMessageBubble({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return AnimatedLoopCloudinarySticker(secureUrl: url, maxLoops: 2);
  }
}
