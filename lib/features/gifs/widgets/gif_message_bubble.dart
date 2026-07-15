import 'package:flutter/material.dart';
import '../utils/loop_limited_gif.dart';

class GifMessageBubble extends StatelessWidget {
  final String url;
  final bool isMe;

  const GifMessageBubble({super.key, required this.url, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(18),
        topRight: const Radius.circular(18),
        bottomLeft: Radius.circular(isMe ? 18 : 0),
        bottomRight: Radius.circular(isMe ? 0 : 18),
      ),
      child: LoopLimitedGif(url: url, fit: BoxFit.cover, maxLoops: 3),
    );
  }
}
