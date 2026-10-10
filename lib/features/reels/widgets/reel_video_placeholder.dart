import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../models/reel_model.dart';

class ReelVideoPlaceholder extends StatelessWidget {
  final YoutubePlayerController? controller;
  final ReelModel reel;

  const ReelVideoPlaceholder({
    super.key,
    required this.controller,
    required this.reel,
  });

  Widget _thumbnail() {
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AppNetworkImage(
            imageUrl: reel.thumbnailUrl,
            fit: BoxFit.cover,
            placeholder:
                (context, url) => const ColoredBox(
                  color: Colors.black,
                  child: Center(child: CustomLoadingIndicator(radius: 14)),
                ),
            errorWidget: (_, __, ___) => const SizedBox.shrink(),
          ),
          const Center(child: CustomLoadingIndicator(radius: 16)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = this.controller;
    if (controller == null) return _thumbnail();

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
          child: _thumbnail(),
        );
      },
    );
  }
}
