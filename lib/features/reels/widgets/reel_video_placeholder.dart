import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../model/reel_model.dart';

class ReelVideoPlaceholder extends StatelessWidget {
  final YoutubePlayerController controller;
  final ReelModel reel;

  const ReelVideoPlaceholder({
    super.key,
    required this.controller,
    required this.reel,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<YoutubePlayerValue>(
      stream: controller.stream.distinct(
        (prev, next) => prev.playerState == next.playerState,
      ),
      initialData: controller.value,
      builder: (context, snapshot) {
        final state = snapshot.data?.playerState ?? PlayerState.unknown;
        final isVisible =
            state != PlayerState.playing &&
            state != PlayerState.paused &&
            state != PlayerState.ended;

        return AnimatedOpacity(
          opacity: isVisible ? 1 : 0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          child: ColoredBox(
            color: Colors.black,
            child: CachedNetworkImage(
              imageUrl: reel.thumbnailUrl,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}
